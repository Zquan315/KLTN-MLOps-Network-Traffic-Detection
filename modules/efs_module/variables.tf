variable "efs_name" {
  description = "Name of the EFS file system"
  type        = string
}

variable "creation_token" {
  description = "A unique name used as reference when creating the EFS"
  type        = string
}

variable "encrypted" {
  description = "Whether to encrypt the EFS file system"
  type        = bool
  default     = true
}

variable "performance_mode" {
  description = "The file system performance mode. Can be either generalPurpose or maxIO"
  type        = string
  default     = "generalPurpose"
}

variable "throughput_mode" {
  description = "Throughput mode for the file system. Valid values: bursting, provisioned, or elastic"
  type        = string
  default     = "bursting"
}

variable "transition_to_ia" {
  description = "Indicates how long it takes to transition files to the IA storage class. Valid values: AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of subnet IDs for EFS mount targets"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for EFS mount targets"
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# Prometheus user configuration
variable "prometheus_uid" {
  description = "UID for Prometheus user"
  type        = number
  default     = 65534
}

variable "prometheus_gid" {
  description = "GID for Prometheus user"
  type        = number
  default     = 65534
}

# Grafana user configuration
variable "grafana_uid" {
  description = "UID for Grafana user"
  type        = number
  default     = 472
}

variable "grafana_gid" {
  description = "GID for Grafana user"
  type        = number
  default     = 472
}

# Alertmanager user configuration
variable "alertmanager_uid" {
  description = "UID for Alertmanager user"
  type        = number
  default     = 65534
}

variable "alertmanager_gid" {
  description = "GID for Alertmanager user"
  type        = number
  default     = 65534
}
