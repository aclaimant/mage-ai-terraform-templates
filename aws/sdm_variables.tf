variable "sdm_token" {
  description = "Token to install SDM relay"
}

variable "ssh_key" {
  description = "Creates EC2 instances with public key for access"
  type        = string
  default     = null
}

variable "gateway_listen_port" {
  description = "Port for strongDM gateways to listen for incoming connections"
  type        = number
  default     = 5000
}

variable "tags" {
  default = {
    created_by = "joel@aclaimant.com"
    stack      = "mage-${var.app_environment}"
  }
}


#################
# Sources latest Amazon Linux 2 AMI ID
#################
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "state"
    values = ["available"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}
