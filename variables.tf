variable "db_master_username" {
  description = "Database administrator username; provide through tfvars"
  type        = string
  sensitive   = true
}

variable "aurora_engine_version" {
  description = "Initial Aurora MySQL version; AWS manages subsequent minor upgrades"
  type        = string
  default     = "8.4.8"
}

variable "db_instance_class" {
  description = "Small provisioned class; confirm engine and region support"
  type        = string
  default     = "db.t4g.medium"
}

variable "db_backup_retention_days" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7

  validation {
    condition = (
      var.db_backup_retention_days >= 1 &&
      var.db_backup_retention_days <= 35 &&
      floor(var.db_backup_retention_days) == var.db_backup_retention_days
    )
    error_message = "Backup retention must be a whole number from 1 to 35."
  }
}

variable "db_backup_window" {
  description = "Daily automated backup window in UTC"
  type        = string
  default     = "03:00-04:00"
}
