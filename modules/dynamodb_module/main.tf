resource "aws_dynamodb_table" "ids_log_system" {
  name         = var.table_name           
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "id"
  range_key = "timestamp"

  attribute { 
    name = "id"
    type = "S"
  }
  attribute { 
    name = "timestamp"
    type = "N" 
  }
  attribute { 
    name = "label"
    type = "S" 
  }
  attribute { 
    name = "content"
    type = "S" 
  }

  global_secondary_index {
    name            = "gsi_label"
    hash_key        = "label"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  # GSI cho search content (hash = content, range = timestamp)
  # Thực tế DynamoDB ko hỗ trợ LIKE, nhưng GSI này cho phép query theo prefix.
  global_secondary_index {
    name            = "gsi_content"
    hash_key        = "content"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  tags = {
    Project = var.table_name
    Env     = "Dev"
  }
}

locals {
  sample_logs = [
    { id="1", timestamp=1736467200000, content="src_ip:10.0.0.5 Normal traffic from IoT-GW", label="benign" },
    { id="2", timestamp=1736468200000, content="src_ip:192.168.1.7 SQLi attempt detected",   label="attack" },
    { id="3", timestamp=1736469200000, content="user:alice User login success",              label="benign" },
    { id="4", timestamp=1736470200000, content="host:web-01 XSS payload blocked",            label="attack" },
    { id="5", timestamp=1736471200000, content="src_ip:10.0.0.8 Health check OK",            label="benign" },
    { id="11", timestamp=1736467200000, content="src_ip:10.0.0.5 Normal traffic from IoT-GW", label="benign" },
    { id="22", timestamp=1736468200000, content="src_ip:192.168.1.7 SQLi attempt detected",   label="attack" },
    { id="33", timestamp=1736469200000, content="user:alice User login success",              label="benign" },
    { id="43", timestamp=1736470200000, content="host:web-01 XSS payload blocked",            label="attack" },
    { id="55", timestamp=1736471200000, content="src_ip:10.0.0.8 Health check OK",            label="benign" },
    { id="111", timestamp=1736467200000, content="src_ip:10.0.0.5 Normal traffic from IoT-GW", label="benign" },
    { id="211", timestamp=1736468200000, content="src_ip:192.168.1.7 SQLi attempt detected",   label="attack" },
    { id="311", timestamp=1736469200000, content="user:alice User login success",              label="benign" },
    { id="411", timestamp=1736470200000, content="host:web-01 XSS payload blocked",            label="attack" },
    { id="511", timestamp=1736471200000, content="src_ip:10.0.0.8 Health check OK",            label="benign" },
    { id="121", timestamp=1736467200000, content="src_ip:10.0.0.5 Normal traffic from IoT-GW", label="benign" },
    { id="221", timestamp=1736468200000, content="src_ip:192.168.1.7 SQLi attempt detected",   label="attack" },
    { id="331", timestamp=1736469200000, content="user:alice User login success",              label="benign" },
    { id="431", timestamp=1736470200000, content="host:web-01 XSS payload blocked",            label="attack" },
    { id="551", timestamp=1736471200000, content="src_ip:10.0.0.8 Health check OK",            label="benign" },
    { id="522", timestamp=1736471200000, content="src_ip:10.0.0.8 Health check OKi",            label="attack" },
  ]
}

resource "aws_dynamodb_table_item" "seed" {
  for_each   = { for s in local.sample_logs : s.id => s }
  table_name = aws_dynamodb_table.ids_log_system.name
  hash_key   = "id"
  range_key  = "timestamp"

  item = jsonencode({
    id        = { S = each.value.id }
    timestamp = { N = tostring(each.value.timestamp) }
    content   = { S = each.value.content }
    label     = { S = each.value.label }
  })
}
