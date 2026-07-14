output "resource_group_id" {
  value = azurerm_resource_group.sample_workload.id
}

output "resource_group_name" {
  value = azurerm_resource_group.sample_workload.name
}

output "tags" {
  value = azurerm_resource_group.sample_workload.tags
}
