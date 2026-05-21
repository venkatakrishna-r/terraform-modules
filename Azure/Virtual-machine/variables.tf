variable "vm_name" {
  type        = string
  description = "Name of the VM"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where NIC will be attached"
}

variable "private_ip_address" {
  type        = string
  description = "Static private IP address"
}

variable "vm_size" {
  type        = string
  default     = "Standard_D2s_v3"
}

variable "availability_zone" {
  type        = string
  default     = null
}

variable "enable_aad_login" {
  type        = bool
  default     = false
}

variable "admin_username" {
  type        = string
}

variable "admin_password" {
  type        = string
  #sensitive   = true
}

variable "tags" {
  type        = map(string)
  default     = {}
}

variable "auto_shutdown_time" {
  description = "Daily auto-shutdown time in HHmm (UTC)"
  type        = string
  default     = null
}

variable "diagnostics_sa_id" {
  description = "Storage account ID for boot diagnostics"
  type        = string
  default     = null
}

variable "data_disks" {
  description = "Map of managed data disks to attach"
  type = map(object({
    name                 = string
    storage_account_type = string
    disk_size_gb         = number
    lun                  = number
    caching              = string
  }))
  default = {}
}


variable "private_ip_address_allocation" {
  type        = string
  default     = "Static"
  description = "Private IP address allocation method (Static or Dynamic)"
}

variable "os_disk" {
  description = "OS disk configuration"
  type = object({
    name                 = string
    storage_account_type = string
    caching              = string
    size_gb              = number
  })
}


variable "image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}

variable "bypass_platform_safety_checks_on_user_schedule_enabled" {
  default = true
}

variable "patch_assessment_mode" {
  default = "AutomaticByPlatform"
}

variable "patch_mode" {
  default = "AutomaticByPlatform"
}

variable "secure_boot_enabled" {
  default = false
}

variable "users" {
  description = "List of local users to create on the VM."
  type = list(object({
    name     = string
    password = string
    groups   = optional(list(string), ["Administrators"])
  }))
  default = []
}