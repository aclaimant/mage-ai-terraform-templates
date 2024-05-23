terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.50"
    }
    sdm = {
      source  = "strongdm/sdm"
      version = ">=3.3.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

provider "sdm" {}

resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = "${var.app_name}-${var.app_environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.app_name}-ecs"
    Environment = var.app_environment
  }
}

resource "aws_cloudwatch_log_group" "log-group" {
  name = "${var.app_name}-${var.app_environment}-logs"

  tags = {
    Application = var.app_name
    Environment = var.app_environment
  }
}

data "template_file" "env_vars" {
  template = file("env_vars.json")

  vars = {
    aws_access_key_id     = module.bucket_reader_s3_user.access_key_id
    aws_secret_access_key = module.bucket_reader_s3_user.secret_access_key
    aws_region_name       = var.aws_region
    # lambda_func_arn = "${aws_lambda_function.terraform_lambda_func.arn}"
    # lambda_func_name = "${aws_lambda_function.terraform_lambda_func.function_name}"
    database_connection_url      = "postgresql+psycopg2://${var.database_user}:${var.database_password}@${aws_db_instance.rds.address}:5432/mage"
    ec2_subnet_id                = aws_subnet.public[0].id
    acl_dbt_db_env               = var.ACL_DBT_DB_ENV
    snowflake_database           = var.SNOWFLAKE_DATABASE
    snowflake_role               = var.SNOWFLAKE_ROLE
    snowflake_warehouse          = var.SNOWFLAKE_WAREHOUSE
    mage_public_host             = var.MAGE_PUBLIC_HOST
    postgres_port                = var.POSTGRES_PORT
    sdm_admin_token              = var.SDM_ADMIN_TOKEN
    disable_notebook_edit_access = var.DISABLE_NOTEBOOK_EDIT_ACCESS
    kinde_dipdash_client_id      = var.KINDE_DIPDASH_CLIENT_ID
    kinde_dipdash_client_secret  = var.KINDE_DIPDASH_CLIENT_SECRET
    kinde_dipdash_domain         = var.KINDE_DIPDASH_DOMAIN
    dipdash_url                  = var.DIPDASH_URL
  }
}

resource "aws_ecs_task_definition" "aws-ecs-task" {
  family = "${var.app_name}-${var.app_environment}-task"

  container_definitions = <<DEFINITION
  [
    {
      "name": "${var.app_name}-${var.app_environment}-container",
      "image": "${var.docker_image}",
      "environment": ${data.template_file.env_vars.rendered},
      "essential": true,
      "mountPoints": [
        {
          "readOnly": false,
          "containerPath": "/home/src",
          "sourceVolume": "${var.app_name}-fs"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.log-group.id}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "${var.app_name}-${var.app_environment}"
        }
      },
      "portMappings": [
        {
          "containerPort": 6789,
          "hostPort": 6789
        }
      ],
      "cpu": ${var.ecs_task_cpu},
      "memory": ${var.ecs_task_memory},
      "networkMode": "awsvpc",
      "ulimits": [
        {
          "name": "nofile",
          "softLimit": 16384,
          "hardLimit": 32768
        }
      ]
    }
  ]
  DEFINITION

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = var.ecs_task_memory
  cpu                      = var.ecs_task_cpu
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn

  volume {
    name = "${var.app_name}-fs"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.file_system.id
      transit_encryption = "ENABLED"
    }
  }

  tags = {
    Name        = "${var.app_name}-ecs-td"
    Environment = var.app_environment
  }

  # depends_on = [aws_lambda_function.terraform_lambda_func]
}

data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.aws-ecs-task.family
}

resource "aws_ecs_service" "aws-ecs-service" {
  name                 = "${var.app_name}-${var.app_environment}-ecs-service"
  cluster              = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition      = "${aws_ecs_task_definition.aws-ecs-task.family}:${max(aws_ecs_task_definition.aws-ecs-task.revision, data.aws_ecs_task_definition.main.revision)}"
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true

  network_configuration {
    subnets          = aws_subnet.public.*.id
    assign_public_ip = true
    security_groups = [
      aws_security_group.service_security_group.id,
      aws_security_group.load_balancer_security_group.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "${var.app_name}-${var.app_environment}-container"
    container_port   = 6789
  }

  depends_on = [aws_lb_listener.listener]
}

resource "aws_security_group" "service_security_group" {
  vpc_id = aws_vpc.aws-vpc.id

  ingress {
    from_port       = 6789
    to_port         = 6789
    protocol        = "tcp"
    cidr_blocks     = ["${chomp(aws_eip.relay.public_ip)}/32"]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.app_name}-service-sg"
    Environment = var.app_environment
  }
}

