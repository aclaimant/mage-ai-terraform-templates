# vpc.tf | VPC Configuration

resource "aws_vpc" "aws-vpc" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "${var.app_name}-${var.app_environment}-vpc"
    Environment = var.app_environment
  }
}

# resource "aws_default_security_group" "default" {
#   vpc_id = aws_vpc.awc-vpc.id
#
#   ingress {
#     protocol  = -1
#     self      = true
#     from_port = 0
#     to_port   = 0
#   }
#
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = aws_vpc.awc-vpc.id

  depends_on = [aws_vpc.awc-vpc]
}
