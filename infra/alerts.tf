# --- Action Group (email notifications) ---
resource "azurerm_monitor_action_group" "email" {
  name                = "ag-email-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "email-ag"

  email_receiver {
    name          = "admin-email"
    email_address = var.alert_email
  }
}

# --- Alert: High CPU ---
resource "azurerm_monitor_metric_alert" "high_cpu" {
  name                = "alert-high-cpu-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_linux_virtual_machine.web.id]
  description         = "Alert when average CPU exceeds 80% over 5 minutes"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.email.id
  }
}

# --- Alert: VM Heartbeat Missing ---
resource "azurerm_monitor_metric_alert" "heartbeat_missing" {
  name                = "alert-heartbeat-missing-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_linux_virtual_machine.web.id]
  description         = "Alert when VM stops sending heartbeat for 5 minutes"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "VmAvailabilityMetric"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.email.id
  }
}