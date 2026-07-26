# Project 4: AWS VPC + EC2 Web App Environment

## Summary
A VPC with proper public/private subnet separation, a NAT gateway for outbound-only
private access, and a bastion pattern that proves the network boundary actually works —
not just that it was configured.

## Architecture
- VPC: `10.0.0.0/16`
- Public subnet (`10.0.1.0/24`): Internet Gateway route, EC2 web/bastion instance, NAT Gateway
- Private subnet (`10.0.2.0/24`): EC2 instance, no public IP, routes outbound through NAT
- Security groups: public instance allows 80/22 (SSH scoped to a single admin IP); private
  instance allows SSH only from the public instance's security group, not from any CIDR

## Verification
Two-directional proof, not just "terraform apply succeeded":

1. **Direct reachability test (expected to fail):** attempted a raw TCP connection to the
   private instance's private IP from outside the VPC entirely. Timed out — no route exists,
   confirming the "private" subnet is actually private.
2. **NAT egress test (expected to succeed):** SSH'd into the bastion, hopped to the private
   instance, and ran `curl https://checkip.amazonaws.com` from inside it. The returned IP
   matched the NAT Gateway's Elastic IP exactly, proving the private instance's outbound
   traffic is genuinely routed through the NAT Gateway — not just "some internet access exists."

## Built with
Terraform (AWS provider ~> 5.0). All resources tagged (`Project`, `Environment`, `Owner`).
Torn down after verification — see `terraform destroy` in the repo history / commit log.
