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

resource "azurerm_resource_group" "sample_workload" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Owner       = var.owner
    Environment = var.environment
    Project     = var.project_name
    CostCenter  = var.cost_center
  }
}
