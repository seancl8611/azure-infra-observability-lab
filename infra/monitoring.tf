# --- Log Analytics Workspace ---
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-infra-lab-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# --- Azure Monitor Agent Extension ---
resource "azurerm_virtual_machine_extension" "ama" {
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.web.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
}

# --- Data Collection Rule ---
resource "azurerm_monitor_data_collection_rule" "linux_vm" {
  name                = "dcr-linux-vm-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  kind                = "Linux"

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.main.id
      name                  = "log-analytics-destination"
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["log-analytics-destination"]
  }

  data_flow {
    streams      = ["Microsoft-Perf"]
    destinations = ["log-analytics-destination"]
  }

  data_sources {
    syslog {
      facility_names = ["auth", "authpriv", "cron", "daemon", "kern", "syslog", "user"]
      log_levels     = ["Alert", "Critical", "Emergency", "Error", "Warning", "Notice", "Info"]
      name           = "syslog-datasource"
      streams        = ["Microsoft-Syslog"]
    }

    performance_counter {
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "Processor(*)\\% Processor Time",
        "Memory(*)\\% Used Memory",
        "LogicalDisk(*)\\% Free Space",
        "LogicalDisk(*)\\Free Megabytes",
        "Network(*)\\Total Bytes Transmitted",
        "Network(*)\\Total Bytes Received"
      ]
      name = "perf-datasource"
    }
  }
}

# --- Associate DCR with VM ---
resource "azurerm_monitor_data_collection_rule_association" "linux_vm" {
  name                    = "dcra-linux-vm-${var.environment}"
  target_resource_id      = azurerm_linux_virtual_machine.web.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.linux_vm.id
}