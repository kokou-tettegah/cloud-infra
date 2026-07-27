# ---------------------------------------------------------------------------
# Provider: Azure Resource Manager
# ---------------------------------------------------------------------------
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# features {} is REQUIRED by the azurerm provider even when empty.
provider "azurerm" {
  features {}
}

# ---------------------------------------------------------------------------
# Resource group: the container everything else lives in.
# In Azure, every resource MUST belong to exactly one resource group.
# (No AWS equivalent - AWS resources live loose in a region.)
# ---------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = "rg-cld005-vnet-web-app"
  location = "eastus"
  tags     = var.tags
}

# ---------------------------------------------------------------------------
# Virtual Network: the private IP space (10.1.0.0/16).
# Non-overlapping with Project 4's AWS VPC (10.0.0.0/16) on purpose,
# so the two could be peered later without a CIDR collision.
# ---------------------------------------------------------------------------
resource "azurerm_virtual_network" "main" {
  name                = "vnet-cld005"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# ---------------------------------------------------------------------------
# Public subnet (10.1.1.0/24): will hold the internet-facing web VM.
# In Azure a subnet is just an address range here - what makes it
# "public" is the NSG rules + the VM having a public IP, NOT a route
# table pointing at an internet gateway (Azure has no IGW concept -
# outbound internet is the platform default).
# ---------------------------------------------------------------------------
resource "azurerm_subnet" "public" {
  name                 = "snet-public"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.1.0/24"]
}

# ---------------------------------------------------------------------------
# Private subnet (10.1.2.0/24): will hold the app VM with no public IP.
# Its outbound internet path will be forced through a NAT Gateway
# (added in chunk 2), and its NSG will only trust the public subnet.
# ---------------------------------------------------------------------------
resource "azurerm_subnet" "private" {
  name                 = "snet-private"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.2.0/24"]
}

# ---------------------------------------------------------------------------
# NAT Gateway: gives the PRIVATE subnet a deliberate outbound-only internet
# path with a single, stable public IP. This is the Azure mirror of Project
# 4's AWS NAT Gateway - but note two differences:
#   1. In AWS, NAT worked via a route table entry (0.0.0.0/0 -> nat-xxxx).
#      In Azure, you ASSOCIATE the NAT Gateway directly to the subnet - no
#      route table needed. The association overrides default outbound.
#   2. Azure subnets have default outbound already; we add explicit NAT so
#      the private VM's egress IP is predictable (needed to PROVE traffic
#      exits through here, same as the AWS Elastic IP match in Project 4).
# ---------------------------------------------------------------------------

# Static public IP that the NAT Gateway will present as the egress address.
# Standard SKU + Static is required for NAT Gateway association.
resource "azurerm_public_ip" "nat" {
  name                = "pip-nat-cld005"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# The NAT Gateway itself.
resource "azurerm_nat_gateway" "main" {
  name                = "nat-cld005"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard"
  tags                = var.tags
}

# Bind the public IP to the NAT Gateway (separate resource in azurerm).
resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

# Associate the NAT Gateway to the PRIVATE subnet only.
# This is what forces the private VM's outbound traffic through the NAT.
# The public subnet is deliberately NOT associated - its VM uses its own
# public IP for two-way traffic instead.
resource "azurerm_subnet_nat_gateway_association" "private" {
  subnet_id      = azurerm_subnet.private.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

# ---------------------------------------------------------------------------
# NSG for the PUBLIC subnet (web tier).
# Key Azure differences from AWS security groups:
#   - NSGs use NUMBERED PRIORITY rules (lower number = evaluated first),
#     not just a flat allow-list. AWS SGs have no priority concept.
#   - NSGs have an implicit final DENY-ALL, plus default rules that ALLOW
#     intra-VNet traffic and Azure Load Balancer probes. AWS SGs deny all
#     inbound by default with no built-in allows.
#   - NSGs are stateful (like AWS SGs) - return traffic is auto-allowed.
# Least privilege here: HTTP open to the world, SSH only from admin IP.
# ---------------------------------------------------------------------------
resource "azurerm_network_security_group" "public" {
  name                = "nsg-public"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  security_rule {
    name                       = "Allow-HTTP-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH-From-Admin"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_ip
    destination_address_prefix = "*"
  }
}

# ---------------------------------------------------------------------------
# NSG for the PRIVATE subnet (app tier).
# The big Azure gotcha vs AWS: Azure NSGs CANNOT reference another NSG as a
# source (AWS lets one SG say "allow from sg-xxxx"). The closest equivalent
# is to trust the source SUBNET's CIDR, or use an Application Security Group.
# We trust the public subnet's CIDR (10.1.1.0/24) here - simple and honest -
# and note ASGs as the more granular option in the README.
# SSH is allowed only from the public subnet, so the only way in is to hop
# through the web VM (the bastion pattern from Project 4).
# ---------------------------------------------------------------------------
resource "azurerm_network_security_group" "private" {
  name                = "nsg-private"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  security_rule {
    name                       = "Allow-SSH-From-PublicSubnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.1.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-All-Other-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Attach each NSG to its subnet (subnet-level attachment, per the ticket).
resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private.id
}

# ---------------------------------------------------------------------------
# PUBLIC VM (web tier) - runs nginx, internet-facing.
# In Azure, a VM is assembled from separate resources (unlike AWS where an
# EC2 instance bundles more together):
#   - a Public IP (so the internet can reach it)
#   - a NIC (network interface) that binds the VM to the subnet + public IP
#   - the VM itself, which references the NIC
# ---------------------------------------------------------------------------

# Public IP for the web VM (this is DIFFERENT from the NAT Gateway's IP -
# this one is for INBOUND traffic to the web server; the NAT IP was for the
# private VM's OUTBOUND traffic).
resource "azurerm_public_ip" "web" {
  name                = "pip-web-cld005"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# NIC for the web VM: places it in the PUBLIC subnet and attaches the public IP.
resource "azurerm_network_interface" "web" {
  name                = "nic-web-cld005"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id
  }
}

# The web VM. custom_data runs a cloud-init script on first boot that
# installs and starts nginx - so the server is serving immediately, no
# manual SSH-in-and-install step.
resource "azurerm_linux_virtual_machine" "web" {
  name                  = "vm-web"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  size                  = var.vm_size
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.web.id]
  tags                  = var.tags

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-arm64"
    version   = "latest"
  }

  # cloud-init: install nginx on first boot. base64encode is required.
  custom_data = base64encode(<<-CLOUDINIT
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    echo "<h1>CLD-005 web VM - nginx is serving</h1>" > /var/www/html/index.html
    systemctl enable nginx
    systemctl restart nginx
  CLOUDINIT
  )
}

# ---------------------------------------------------------------------------
# PRIVATE VM (app tier) - NO public IP, reachable only via the web VM.
# Same pattern minus the public IP: NIC in the private subnet, no
# public_ip_address_id. Its only outbound path is the NAT Gateway.
# ---------------------------------------------------------------------------
resource "azurerm_network_interface" "app" {
  name                = "nic-app-cld005"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
    # No public_ip_address_id - this is what makes it private.
  }
}

resource "azurerm_linux_virtual_machine" "app" {
  name                  = "vm-app"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  size                  = var.vm_size
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.app.id]
  tags                  = var.tags

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-arm64"
    version   = "latest"
  }
}

# ---------------------------------------------------------------------------
# STORAGE ACCOUNT + private blob container.
# This is the Azure counterpart to Project 1's S3 bucket. Key comparisons:
#   - Naming: storage account names are GLOBALLY unique, 3-24 chars,
#     lowercase letters + numbers ONLY (no hyphens). Stricter than S3.
#   - "Block public access": Azure's account-level public access toggle is
#     the rough equivalent of S3 Block Public Access. We disable it here so
#     no container can be made public even by accident.
#   - Encryption at rest is ON BY DEFAULT in Azure (Microsoft-managed keys)
#     and cannot be turned off - unlike S3 where you opt in. So there's no
#     explicit "enable encryption" line; it's implicit. Worth noting in docs.
# ---------------------------------------------------------------------------
resource "azurerm_storage_account" "main" {
  name                     = "stkokoucld05"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Disallow public blob access at the account level (defense in depth:
  # even if a container is set to public, this overrides it to private).
  allow_nested_items_to_be_public = false

  # Require TLS for all traffic.
  min_tls_version = "TLS1_2"

  tags = var.tags
}

# A private blob container inside the account. container_access_type
# "private" = no anonymous read access (the Azure equivalent of a
# fully-private S3 bucket).
resource "azurerm_storage_container" "main" {
  name                  = "assets"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}
