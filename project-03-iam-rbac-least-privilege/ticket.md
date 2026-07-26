# Ticket: Least-Privilege Access Review

Requested by: Security Lead (simulated)
Priority: High

Audit flagged that our admin users have broad access even for routine 
tasks. We need scoped-down accounts for day-to-day work on both clouds.

Requirements:
- AWS: Create an IAM user who can ONLY manage S3 — nothing else
- Azure: Assign a built-in Reader role to a resource group (view-only, 
  no changes allowed)
- Prove the restriction works: attempt an out-of-scope action on each 
  and document the denial
- Compare both models in writing

Success criteria: Both restricted identities created, tested, and 
documented with the actual denial errors as evidence.
