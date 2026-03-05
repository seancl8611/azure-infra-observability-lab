output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "location" {
  value = azurerm_resource_group.main.location
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.web.name
}

output "vm_public_ip" {
  value = azurerm_public_ip.web_vm.ip_address
}

output "vm_public_ip_resource_id" {
  value = azurerm_public_ip.web_vm.id
}

output "log_analytics_workspace_name" {
  value = azurerm_log_analytics_workspace.main.name
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.main.id
}

output "action_group_name" {
  value = azurerm_monitor_action_group.email.name
}