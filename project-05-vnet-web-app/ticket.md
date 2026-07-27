# Ticket CLD-005: Provision Azure web application network environment

## Requestor
VP of Operations (simulated)

## Summary
Stand up an Azure-side equivalent of the AWS web environment (CLD-004)
so the team can evaluate the two clouds side by side.

## Requirements
- A dedicated VNet (10.1.0.0/16) with a public subnet and a private subnet
- A Linux VM running nginx in the public subnet:
    - reachable on HTTP (port 80) from the internet
    - reachable on SSH (port 22) ONLY from the admin IP
- A private Linux VM in the private subnet:
    - NO public IP
    - reachable only from the public subnet
    - outbound internet access via a NAT Gateway (for package updates)
- A Storage Account with a private Blob container:
    - no anonymous/public access
    - encrypted at rest
- NSGs following least privilege (subnet-level attachment)
- All resources tagged per the four-tag governance standard from CLD-002
    (Owner, Environment, Project, CostCenter)

## Constraints
- Terraform only (no portal click-ops)
- Verified via Azure CLI, not just "apply succeeded"
- Torn down after documentation (NAT Gateway is not free-tier)

## Definition of done
- Public VM serves nginx over HTTP from the internet
- Private VM reaches the internet outbound, proven to go through the NAT Gateway
- Direct inbound connection to the private VM fails
- Storage blob container rejects anonymous access
- All resources tagged, documented, pushed clean, torn down
