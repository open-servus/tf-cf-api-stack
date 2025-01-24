resource "aws_lb" "nlb" {
  name               = "${var.application}-${var.environment}"
  internal           = true
  load_balancer_type = "network"
  subnets            = [join("", aws_subnet.sp1.*.id), join("", aws_subnet.sp2.*.id), join("", aws_subnet.sp3.*.id)]

  security_groups            = [aws_security_group.sg.id]
  enable_deletion_protection = false

  tags = {
    Environment = var.environment
  }
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_lb.nlb.id
  port              = "443"
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.tcp_443.id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "tcp_443" {
  name                 = "vpce-${var.environment}"
  port                 = 443
  protocol             = "TCP"
  target_type          = "ip"
  vpc_id               = aws_vpc.main.id
  deregistration_delay = 300

  health_check {
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }
}

data "aws_network_interface" "net-endpoint-private-ip" {
  for_each = { for k, v in [tolist(aws_vpc_endpoint.api.network_interface_ids)[0], tolist(aws_vpc_endpoint.api.network_interface_ids)[1], tolist(aws_vpc_endpoint.api.network_interface_ids)[2]] : k => v }
  id       = each.value
}

resource "aws_lb_target_group_attachment" "attach" {
  for_each         = data.aws_network_interface.net-endpoint-private-ip
  target_group_arn = aws_lb_target_group.tcp_443.arn
  target_id        = each.value.private_ip
}
