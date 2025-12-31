output "efs_id" {
  description = "The ID of the EFS file system"
  value       = aws_efs_file_system.efs.id
}

output "efs_arn" {
  description = "The ARN of the EFS file system"
  value       = aws_efs_file_system.efs.arn
}

output "efs_dns_name" {
  description = "The DNS name of the EFS file system"
  value       = aws_efs_file_system.efs.dns_name
}

output "mount_target_ids" {
  description = "List of EFS mount target IDs"
  value       = aws_efs_mount_target.mount_target[*].id
}

output "mount_target_dns_names" {
  description = "List of EFS mount target DNS names"
  value       = aws_efs_mount_target.mount_target[*].dns_name
}

output "prometheus_access_point_id" {
  description = "The ID of the Prometheus access point"
  value       = aws_efs_access_point.prometheus.id
}

output "prometheus_access_point_arn" {
  description = "The ARN of the Prometheus access point"
  value       = aws_efs_access_point.prometheus.arn
}

output "grafana_access_point_id" {
  description = "The ID of the Grafana access point"
  value       = aws_efs_access_point.grafana.id
}

output "grafana_access_point_arn" {
  description = "The ARN of the Grafana access point"
  value       = aws_efs_access_point.grafana.arn
}

output "alertmanager_access_point_id" {
  description = "The ID of the Alertmanager access point"
  value       = aws_efs_access_point.alertmanager.id
}

output "alertmanager_access_point_arn" {
  description = "The ARN of the Alertmanager access point"
  value       = aws_efs_access_point.alertmanager.arn
}
