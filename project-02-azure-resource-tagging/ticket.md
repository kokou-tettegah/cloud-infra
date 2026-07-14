# Ticket: Resource Group Tagging & Governance

Requested by: Cloud Infrastructure Lead (simulated)
Priority: Medium

We need consistent tagging across our Azure resource groups for cost 
tracking and ownership visibility.

Requirements:
- Create a resource group for a sample workload
- Apply standard tags: Owner, Environment, Project, CostCenter
- Verify tags are queryable via CLI
- Document the tagging convention for future resource groups

Success criteria: Resource group created via Terraform, fully tagged, 
tags confirmed via az CLI query.
