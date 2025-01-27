// This Terraform configuration defines an AWS API Gateway REST API, deployment, and stage.

// The aws_api_gateway_rest_api resource creates a REST API in API Gateway.
// - The `body` attribute defines the OpenAPI specification for the API, including paths and methods.
// - The `name` attribute sets the name of the API using the application and environment variables.
// - The `put_rest_api_mode` attribute is set to "merge" to update the API configuration.
// - The `policy` attribute defines an IAM policy allowing all principals to invoke the API.
// - The `endpoint_configuration` block configures the API to be private and associates it with a VPC endpoint.

// The aws_api_gateway_deployment resource creates a deployment for the REST API.
// - The `rest_api_id` attribute links the deployment to the REST API.
// - The `triggers` attribute forces a redeployment when the API definition changes.
// - The `lifecycle` block ensures the deployment is created before the previous one is destroyed.

// The aws_api_gateway_stage resource creates a stage for the REST API deployment.
// - The `deployment_id` attribute links the stage to the deployment.
// - The `rest_api_id` attribute links the stage to the REST API.
// - The `stage_name` attribute sets the name of the stage using the environment variable.
resource "aws_api_gateway_rest_api" "main" {
  body = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "${var.application}-${var.environment}"
      version = "1.0"
    }
    paths = {
      "/path1" = {
        get = {
          x-amazon-apigateway-integration = {
            httpMethod           = "GET"
            payloadFormatVersion = "1.0"
            type                 = "HTTP_PROXY"
            uri                  = "https://ip-ranges.amazonaws.com/ip-ranges.json"
          }
        }
      }
    }
  })

  name              = "${var.application}-${var.environment}"
  put_rest_api_mode = "merge"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "execute-api:Invoke",
        Resource  = "execute-api:/*/*/*"
      }
    ]
  })

  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [aws_vpc_endpoint.api.id]
  }
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.main.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.environment
}