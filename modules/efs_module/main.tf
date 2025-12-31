# Create EFS File System
resource "aws_efs_file_system" "efs" {
  creation_token = var.creation_token
  encrypted      = var.encrypted

  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode

  # Enable lifecycle management to transition files to IA storage class
  dynamic "lifecycle_policy" {
    for_each = var.transition_to_ia != null ? [1] : []
    content {
      transition_to_ia = var.transition_to_ia
    }
  }

  tags = merge(
    {
      Name = var.efs_name
    },
    var.tags
  )
}

# Create Mount Targets for each subnet
resource "aws_efs_mount_target" "mount_target" {
  count           = length(var.subnet_ids)
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = var.security_group_ids

  # Ensure mount targets are created after the file system
  depends_on = [aws_efs_file_system.efs]
}

# Create Access Points for Prometheus and Grafana
resource "aws_efs_access_point" "prometheus" {
  file_system_id = aws_efs_file_system.efs.id

  posix_user {
    gid = var.prometheus_gid
    uid = var.prometheus_uid
  }

  root_directory {
    path = "/prometheus"
    creation_info {
      owner_gid   = var.prometheus_gid
      owner_uid   = var.prometheus_uid
      permissions = "755"
    }
  }

  tags = merge(
    {
      Name = "${var.efs_name}-prometheus"
    },
    var.tags
  )
}

resource "aws_efs_access_point" "grafana" {
  file_system_id = aws_efs_file_system.efs.id

  posix_user {
    gid = var.grafana_gid
    uid = var.grafana_uid
  }

  root_directory {
    path = "/grafana"
    creation_info {
      owner_gid   = var.grafana_gid
      owner_uid   = var.grafana_uid
      permissions = "755"
    }
  }

  tags = merge(
    {
      Name = "${var.efs_name}-grafana"
    },
    var.tags
  )
}

resource "aws_efs_access_point" "alertmanager" {
  file_system_id = aws_efs_file_system.efs.id

  posix_user {
    gid = var.alertmanager_gid
    uid = var.alertmanager_uid
  }

  root_directory {
    path = "/alertmanager"
    creation_info {
      owner_gid   = var.alertmanager_gid
      owner_uid   = var.alertmanager_uid
      permissions = "755"
    }
  }

  tags = merge(
    {
      Name = "${var.efs_name}-alertmanager"
    },
    var.tags
  )
}
