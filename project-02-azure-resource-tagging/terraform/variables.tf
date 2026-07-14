variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-sample-workload-kokou"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "owner" {
  description = "Resource owner"
  type        = string
  default     = "kokou"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "learning-sandbox"
}

variable "project_name" {
  description = "Project tag"
  type        = string
  default     = "cloud-portfolio"
}

variable "cost_center" {
  description = "Cost center tag"
  type        = string
  default     = "personal-training"
}
