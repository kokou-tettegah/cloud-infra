# Project 1: S3 Bucket for Marketing Assets

## Problem
Marketing needed a secure storage location for campaign assets. Requirements: 
private access only, versioning to protect against accidental overwrite/delete, 
and encryption at rest.

## Solution
Provisioned an S3 bucket using Terraform with:
- **Versioning enabled** — protects against accidental deletes/overwrites
- **Server-side encryption (SSE-S3/AES256)** — encrypts all objects at rest
- **Public access fully blocked** — all four public access block settings enabled
- **Tagged** for cost tracking (Project, Owner, Environment)

## Architecture
## How to Reproduce
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Verification
Confirmed via AWS CLI:
- `aws s3api get-bucket-versioning` → Status: Enabled
- `aws s3api get-public-access-block` → all settings: true
- `aws s3api get-bucket-encryption` → SSEAlgorithm: AES256

## Output
## Cost
$0.00 — within AWS Free Tier limits at this scale.

## Cleanup
Resources destroyed after documentation via `terraform destroy` — 
confirmed removed in AWS Console.

## Skills Demonstrated
Infrastructure as Code (Terraform), AWS S3, IAM, security best practices 
(least privilege, encryption at rest, public access blocking), state management.
