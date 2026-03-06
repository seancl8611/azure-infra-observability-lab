# trigger github actions
resource "azurerm_resource_group" "main" {
  name     = "rg-infra-lab-${var.environment}"
  location = var.location
}