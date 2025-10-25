# ============================================================
# DynamoDB Table for IDS Logging
# ============================================================
resource "aws_dynamodb_table" "ids_flow_logs" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"

  # Flask sử dụng flow_id làm khóa chính
  hash_key = "flow_id"

  # ----------------------------
  # Define attributes
  # ----------------------------
  attribute {
    name = "flow_id"
    type = "S"
  }

  attribute {
    name = "time"
    type = "S"
  }

  attribute {
    name = "label"
    type = "S"
  }

  attribute {
    name = "content"
    type = "S"
  }

  # ----------------------------
  # GSI 1: query theo label
  # ----------------------------
  global_secondary_index {
    name            = "gsi_label"
    hash_key        = "label"
    range_key       = "time"
    projection_type = "ALL"
  }

  # ----------------------------
  # GSI 2: query theo content prefix (tuỳ chọn)
  # ----------------------------
  global_secondary_index {
    name            = "gsi_content"
    hash_key        = "content"
    range_key       = "time"
    projection_type = "ALL"
  }

  tags = {
    Project = var.table_name
    Env     = "Dev"
  }
}

# ============================================================
# Optional: Sample test data for verification (remove in prod)
# ============================================================
locals {
  sample_logs = [
    {
      flow_id = "test-001",
      time    = "2025-10-24 16:00:00",
      content = "Src: 172.16.0.5 → 192.168.50.1 (6), Flow simulated",
      label   = "BENIGN",
      features_json = "{\"Flow Duration\": 1.0, \"Total Fwd Packets\": 2}"
    }
  ]
}

resource "aws_dynamodb_table_item" "seed" {
  for_each   = { for s in local.sample_logs : s.flow_id => s }
  table_name = aws_dynamodb_table.ids_flow_logs.name
  hash_key   = "flow_id"

  item = jsonencode({
    flow_id       = { S = each.value.flow_id }
    time          = { S = each.value.time }
    content       = { S = each.value.content }
    label         = { S = each.value.label }
    features_json = { S = each.value.features_json }
  })
}
