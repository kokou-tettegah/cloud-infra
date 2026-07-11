terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "marketing_assets" {
  bucket = var.bucket_name

  tags = {
    Project     = "marketing-assets"
    Owner       = "kokou"
    Environment = "prod-sim"
  }
}

resource "aws_s3_bucket_versioning" "marketing_assets_versioning" {
  bucket = aws_s3_bucket.marketing_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "marketing_assets_encryption" {
  bucket = aws_s3_bucket.marketing_assets.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "marketing_assets_block" {
  bucket = aws_s3_bucket.marketing_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
