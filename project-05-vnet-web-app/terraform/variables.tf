# Admin IP allowed to SSH into the public VM.
# Real value goes in terraform.tfvars (gitignored), never hardcoded here.
variable "admin_ip" {
  description = "Your public IP in CIDR form, e.g. 203.0.113.10/32"
  type        = string
}

# SSH public key material for the VMs.
# We generate the key pair manually (CLI) and pass the PUBLIC key here.
variable "ssh_public_key" {
  description = "Contents of the SSH public key file"
  type        = string
}

# Standard governance tags (from CLD-002).
variable "tags" {
  description = "Standard four-tag governance set"
  type        = map(string)
  default = {
    Owner       = "Kokou"
    Environment = "Sandbox"
    Project     = "CLD-005"
    CostCenter  = "Learning"
  }
}

# VM size. Made a variable because SKU availability is region/time-dependent
# in Azure - a valid size can be temporarily out of capacity, forcing a swap.
# B1s hit a SkuNotAvailable capacity error in eastus; B2s is the fallback.
variable "vm_size" {
  description = "Azure VM size for both VMs"
  type        = string
  default     = "Standard_D2ps_v5"
}
