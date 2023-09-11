locals {
  sdm_node_name   = "${var.app_name}-${var.app_environment}-sdm"
  relay_subnet_id = var.private_subnets[0]

  dev_mode = true
}

resource "aws_security_group" "this" {
  name        = "${local.sdm_node_name}-sg"
  description = "StrongDM security group for ${local.sdm_node_name}"

  vpc_id = aws_vpc.aws-vpc.id

  "ingress" {
    from_port   = var.gateway_listen_port
    to_port     = var.gateway_listen_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  timeouts {
    delete = "2m"
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = merge({ "Name" = "${local.sdm_node_name}-node" }, var.tags, )
}

#### OK

resource "sdm_node" "relay" {
  relay {
    name = "${local.sdm_node_name}-relay"
  }
}

resource "aws_instance" "relay" {

  ami           = data.aws_ami.amazon_linux_2.image_id
  instance_type = local.dev_mode ? "t3.micro" : "t3.medium"
  user_data     = templatefile("${path.module}/templates/relay_install/relay_install.tftpl", { SDM_TOKEN = "${var.sdm_token}" })

  key_name = var.ssh_key

  credit_specification {
    # Prevents CPU throttling and potential performance issues with Gateway
    cpu_credits = "unlimited"
  }

  # Relay Attributes
  subnet_id              = local.relay_subnet_id
  vpc_security_group_ids = [aws_security_group.this.id]

  lifecycle {

    # Prevents Instance from respawning when Amazon Linux 2 is updated
    ignore_changes = [ami]

    # Used to prevent EIP from failing to associate
    # https://github.com/terraform-providers/terraform-provider-aws/issues/2689
    create_before_destroy = true
  }

  tags = merge({ "Name" = sdm_node.relay.name }, var.tags, )
}
