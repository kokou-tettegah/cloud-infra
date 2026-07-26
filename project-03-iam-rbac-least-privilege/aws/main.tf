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

resource "aws_iam_user" "s3_limited_user" {
  name = "s3-readonly-analyst"
  tags = {
    Project = "cloud-portfolio"
    Purpose = "least-privilege-demo"
  }
}

resource "aws_iam_user_policy" "s3_only_policy" {
  name = "s3-only-access"
  user = aws_iam_user.s3_limited_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket", "s3:PutObject"]
        Resource = "*"
      }
    ]
  })
}
