# --- Public IP ---
resource "azurerm_public_ip" "web_vm" {
  name                = "pip-web-vm-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# --- Network Interface ---
resource "azurerm_network_interface" "web_vm" {
  name                = "nic-web-vm-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web_vm.id
  }
}

# --- Linux Virtual Machine ---
resource "azurerm_linux_virtual_machine" "web" {
  name                = "vm-web-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # CHANGED: Standard_B1s was unavailable in eastus (SkuNotAvailable).
  # Try this size first; if it fails, use Standard_B2s or Standard_DS1_v2.
  size           = "Standard_D2s_v3"
  admin_username = "azureadmin"

  network_interface_ids = [
    azurerm_network_interface.web_vm.id
  ]

  admin_ssh_key {
    username   = "azureadmin"
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(file("${path.module}/cloud-init.yaml"))

  identity {
    type = "SystemAssigned"
  }
}

# --- Auto-Shutdown (cost control) ---
resource "azurerm_dev_test_global_vm_shutdown_schedule" "web" {
  virtual_machine_id = azurerm_linux_virtual_machine.web.id
  location           = azurerm_resource_group.main.location
  enabled            = true

  daily_recurrence_time = "2300"
  timezone              = "Eastern Standard Time"

  notification_settings {
    enabled = false
  }
}