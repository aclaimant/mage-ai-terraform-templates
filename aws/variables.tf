variable "AWS_ACCESS_KEY_ID" {
  type    = string
  default = "AWS_ACCESS_KEY_ID"
}

variable "AWS_SECRET_ACCESS_KEY" {
  type    = string
  default = "AWS_SECRET_ACCESS_KEY"
}

variable "DATABASE_CONNECTION_URL" {
  type    = string
  default = ""
}

variable "app_count" {
  type    = number
  default = 1
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "us-west-2"
}

variable "aws_cloudwatch_retention_in_days" {
  type        = number
  description = "AWS CloudWatch Logs Retention in Days"
  default     = 30
}

variable "app_name" {
  type        = string
  description = "Application Name"
  default     = "mage-data-prep"
}

variable "app_environment" {
  type        = string
  description = "Application Environment"
  default     = "production"
}

variable "cidr" {
  description = "The CIDR block for the VPC."
  default     = "10.32.0.0/16"
}

variable "database_user" {
  type        = string
  description = "The username of the Postgres database."
  default     = "mageuser"
}

variable "database_password" {
  type        = string
  description = "The password of the Postgres database."
  sensitive   = true
}

variable "docker_image" {
  description = "Docker image url used in ECS task."
}

variable "ecs_task_cpu" {
  description = "ECS task cpu"
  default     = 512
}

variable "ecs_task_memory" {
  description = "ECS task memory"
  default     = 1024
}

variable "public_subnets" {
  description = "List of public subnets"
  default     = ["10.32.100.0/24", "10.32.101.0/24"]
}

variable "private_subnets" {
  description = "List of private subnets"
  default     = ["10.32.0.0/24", "10.32.1.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones"
  default     = ["us-west-2a", "us-west-2b"]
}

variable "ACL_DBT_DB_ENV" {
  type = string
}

variable "SNOWFLAKE_DATABASE" {
  type = string
}

variable "SNOWFLAKE_ROLE" {
  type = string
}

variable "SNOWFLAKE_WAREHOUSE" {
  type = string
}

variable "MAGE_PUBLIC_HOST" {
  type = string
}

variable "POSTGRES_PORT" {
  type = number
}

variable "SDM_ADMIN_TOKEN" {
  type = string
}

variable "DISABLE_NOTEBOOK_EDIT_ACCESS" {
  type        = string
  description = "See https://docs.mage.ai/production/configuring-production-settings/overview#read-only-access"
  default     = "2"
}

variable "KINDE_DIPDASH_CLIENT_ID" {
  type = string
  description = "Client ID to pass to authenticator for dip-dash API tokens"
}

variable "KINDE_DIPDASH_CLIENT_SECRET" {
  type = string
  description = "Client secret to pass to authenticator for dip-dash API tokens"
}

variable "KINDE_DIPDASH_DOMAIN" {
  type = string
  description = "Base URL for Kinde authenticator API, used for dip-dash access"
}

variable "DIPDASH_URL" {
  type = string
  description = "Base URL for dip-dash API"
}
