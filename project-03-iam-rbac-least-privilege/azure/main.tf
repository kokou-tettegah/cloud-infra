terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "least_privilege_demo" {
  name     = "rg-least-privilege-demo-kokou"
  location = "eastus"

  tags = {
    Project = "cloud-portfolio"
    Purpose = "least-privilege-demo"
  }
}
