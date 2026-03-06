variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "admin_ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "allowed_ssh_ip" {
  description = "Your public IP address for SSH access (use https://ifconfig.me to find it)"
  type        = string
}

variable "alert_email" {
  description = "Email address to receive alert notifications"
  type        = string
}

variable "allowed_http_source" {
  description = "Source for HTTP inbound (use * for public demo, or your IP)"
  type        = string
  default     = "*"
}