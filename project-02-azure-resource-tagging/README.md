# Project 2: Azure Resource Group Tagging & Governance

## Problem
Needed a consistent tagging strategy across Azure resource groups for 
cost tracking and ownership visibility.

## Solution
Provisioned an Azure Resource Group using Terraform with standardized 
tags applied at creation:
- **Owner** — who's responsible for the resource
- **Environment** — deployment stage (learning-sandbox)
- **Project** — which initiative the resource belongs to
- **CostCenter** — for billing/cost allocation tracking

## Architecture
## How to Reproduce
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Verification
Confirmed via Azure CLI (independent of Terraform's own state):
- `az group show --query tags` → all 4 tags present and correct
- `az group show --query location` → eastus confirmed
- `az group list` → resource group confirmed present in subscription

## Output
## Cost
$0.00 — resource groups themselves are free; no billable resources 
were created inside it.

## Cleanup
Resources destroyed after documentation via `terraform destroy` — 
confirmed removed via `az group list`.

## Skills Demonstrated
Terraform on Azure (azurerm provider), resource governance and tagging 
strategy, Azure CLI verification, cross-cloud IaC (comparing AWS provider 
syntax from Project 1 to Azure provider syntax here).

## AWS vs Azure — What Was Different This Time
- **Permissions**: AWS required manually attaching an IAM policy before 
  anything could be created (hit an AccessDenied error in Project 1). 
  Azure's default account is Owner on its own subscription — no equivalent 
  step was needed here.
- **Resource shape**: AWS's S3 bucket needed 4 separate resource blocks 
  (bucket, versioning, encryption, public access block). Azure's resource 
  group tagging needed just 1 resource block — tags are a native property.
- **Provider name**: `aws` vs `azurerm` in the Terraform provider block — 
  otherwise the `init`/`plan`/`apply` workflow was identical.
