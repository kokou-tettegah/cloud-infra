# Project 3: IAM/RBAC Least-Privilege Deep Dive (AWS + Azure)

## Problem
Security audit flagged that admin-level users were being used for routine, narrow-scope tasks. Needed scoped-down identities on both clouds, with proof the restrictions actually work.

## Solution

### AWS
Created IAM user s3-readonly-analyst with a custom policy granting ONLY s3:GetObject, s3:ListBucket, s3:PutObject. Configured as a separate named CLI profile (s3-limited), isolated from the main Kokou-Admin profile.

Verified: list-objects-v2 against a known bucket succeeded. ec2 describe-instances was denied with AccessDenied.

Bonus finding: s3:ListBucket (listing objects inside a known bucket) is a completely different permission from s3:ListAllMyBuckets (enumerating every bucket in the account) - granting one does not grant the other.

### Azure
Created a dedicated resource group (rg-least-privilege-demo-kokou). Created a Service Principal (reader-demo-sp) with the built-in Reader role, scoped to ONLY that resource group.

Verified: az resource list succeeded (read access confirmed). az storage account create was denied with AuthorizationFailed.

## Architecture

AWS side: Kokou-Admin (full access) creates and manages s3-readonly-analyst, which is scoped to only s3:GetObject, s3:ListBucket, and s3:PutObject - no other AWS services.

Azure side: kokoutettegah1@gmail.com (subscription Owner) creates and manages reader-demo-sp, which is scoped to only the Reader role on rg-least-privilege-demo-kokou - no write access, no access outside that resource group.
## How to Reproduce

AWS:
cd aws
terraform init and terraform plan and terraform apply
aws configure --profile s3-limited (paste generated access keys)
aws sts get-caller-identity --profile s3-limited

Azure:
cd azure
terraform init and terraform plan and terraform apply
az ad sp create-for-rbac --name reader-demo-sp --role Reader --scopes the resource group ID
az login --service-principal with appId, password, tenant

## Verification Evidence

AWS denied action error:
AccessDenied - User s3-readonly-analyst is not authorized to perform ec2:DescribeInstances

Azure denied action error:
AuthorizationFailed - The client does not have authorization to perform action Microsoft.Storage/storageAccounts/write over the scope of rg-least-privilege-demo-kokou


## Cost
$0.00 - IAM and RBAC resources are free; no billable compute or storage was created.

## Cleanup
All resources destroyed via terraform destroy on both AWS and Azure sides. Service Principal deleted via az ad sp delete.

## Skills Demonstrated
Least-privilege access control, IAM policy authoring on AWS, RBAC role assignment on Azure, Service Principal creation and scoped authentication, multi-profile CLI configuration, cross-cloud identity model comparison, and credential hygiene.

## AWS IAM vs Azure RBAC Comparison

Restricted identity type: AWS uses an IAM User. Azure uses a Service Principal.

Permission grant unit: AWS attaches an IAM Policy (JSON) directly to the user. Azure assigns a built-in Role bound to a specific scope.

Scoping mechanism: AWS uses the Resource field inside the policy JSON. Azure uses the --scopes flag at role assignment time.

Human vs non-human identity: AWS uses the same IAM user type for both humans and applications. Azure separates these into Users (human) and Service Principals (apps and automation).

Granularity example: AWS distinguishes s3:ListBucket from s3:ListAllMyBuckets very precisely. Azure's Reader role bundles many read actions together at a coarser level.
