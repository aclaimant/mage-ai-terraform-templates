locals {
  bucket_name      = "aclaimant-${var.app_name}-${var.app_environment}-bucket"
  reader_user_name = "${var.app_name}-${var.app_environment}-s3-reader"
}

module "bucket_reader_s3_user" {
  source  = "cloudposse/iam-s3-user/aws"
  version = "1.2.0"

  name         = local.reader_user_name
  s3_actions   = ["s3:GetObject", "s3:ListBucket"]
  s3_resources = aws_s3_bucket.data_bucket.arn

  tags = {
    Name       = local.reader_user_name
    created_by = "terraform"

    VantaOwner       = "joel@aclaimant.com"
    VantaDescription = "User for reading from data bucket"
  }
}

resource "aws_s3_bucket" "data_bucket" {
  bucket        = local.bucket_name
  force_destroy = "false"

  tags = {
    Name       = local.bucket_name
    created_by = "terraform"

    VantaOwner       = "joel@aclaimant.com"
    VantaDescription = "Used for ${var.app_name}-${var.app_environment}"
  }
}

resource "aws_s3_bucket_acl" "data_bucket" {
  bucket = aws_s3_bucket.data_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "data_bucket" {
  bucket = aws_s3_bucket.data_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_bucket" {
  bucket = aws_s3_bucket.data_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

output "id" {
  value = aws_s3_bucket.data_bucket.id
}

output "arn" {
  value = aws_s3_bucket.data_bucket.arn
}


output "reader_name" {
  value = module.bucket_reader_s3_user.user_name
}

output "reader_access_key_id" {
  value     = module.bucket_reader_s3_user.access_key_id
  sensitive = true
}

output "reader_secret_access_key" {
  value     = module.bucket_reader_s3_user.secret_access_key
  sensitive = true
}
