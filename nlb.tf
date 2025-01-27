/*
This Terraform configuration sets up a Network Load Balancer (NLB) with associated resources.

Resources:
1. aws_lb "nlb":
  - Creates a Network Load Balancer with the specified name, internal setting, type, subnets, security groups, and tags.
  - The name is derived from the application and environment variables.
  - The load balancer is internal and of type "network".
  - Subnets are specified by joining the IDs of three subnets.
  - Security groups are assigned.
  - Deletion protection is disabled.
  - Tags include the environment.

2. aws_alb_listener "https":
  - Creates a listener for the NLB on port 443 using the TCP protocol.
  - The default action forwards traffic to the specified target group.

3. aws_lb_target_group "tcp_443":
  - Defines a target group for the NLB with the specified name, port, protocol, target type, VPC ID, and health check settings.
  - The name is derived from the application and environment variables.
  - The target type is "ip".
  - Health check settings include protocol, thresholds, and interval.

4. data "aws_network_interface" "net-endpoint-private-ip":
  - Retrieves network interface data for the VPC endpoint.
  - Uses a for_each loop to iterate over the network interface IDs of the VPC endpoint.

5. aws_lb_target_group_attachment "attach":
  - Attaches the network interfaces to the target group.
  - Uses a for_each loop to iterate over the network interfaces and attach them to the target group using their private IPs.
*/
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
  name                 = "${var.application}-${var.environment}-vpce"
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
