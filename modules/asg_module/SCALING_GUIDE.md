# Multi-Metric Auto Scaling Guide

## 📊 Tổng quan

ASG module hiện hỗ trợ scaling dựa trên **3 metrics**:
- ✅ **CPU Usage** (AWS/EC2)
- ✅ **Memory Usage** (CWAgent)
- ✅ **Disk Usage** (CWAgent)

## 🎯 Chiến lược Scaling

### Scale Out (Tăng instances)
Trigger khi **BẤT KỲ** điều kiện nào sau đây xảy ra:

| Metric | Threshold | Duration | Action |
|--------|-----------|----------|--------|
| **CPU** | ≥ 70% | 2 x 120s | +1 instance |
| **Memory** | ≥ 80% | 2 x 120s | +1 instance |
| **Disk** | ≥ 80% | 2 x 120s | +1 instance |

**Composite Alarm**: Sử dụng `OR` logic - chỉ cần 1 metric vượt ngưỡng là scale out ngay

### Scale In (Giảm instances)
Chỉ trigger khi **TẤT CẢ** điều kiện đều thấp:

| Metric | Threshold | Duration | Action |
|--------|-----------|----------|--------|
| **CPU** | ≤ 50% | 2 x 120s | -1 instance |
| **Memory** | ≤ 40% | 2 x 300s | -1 instance |

**Lưu ý**: Memory scale-in có evaluation period dài hơn để tránh flapping

## 🔧 Cấu hình CloudWatch Agent

### Automatic Installation
CloudWatch Agent được tự động cài đặt qua user_data script:

```bash
# monitoring.sh, ids.sh, honey_pot.sh, etc.
# CloudWatch Agent section đã được thêm vào đầu mỗi script
```

### Metrics được thu thập:

**Memory Metrics:**
- `mem_used_percent` - Phần trăm RAM đã sử dụng
- `mem_available` - RAM khả dụng (MB)
- `mem_used` - RAM đã dùng (MB)

**Disk Metrics:**
- `disk_used_percent` - Phần trăm disk đã sử dụng
- `disk_inodes_free` - Số inodes còn trống

**Aggregation:**
- Group theo `AutoScalingGroupName`
- Metrics interval: 60 giây

## 📈 CloudWatch Alarms

### CPU Alarms (AWS Native)
```
cpu-high: CPU >= 70% for 4 minutes → Scale Out
cpu-low:  CPU <= 50% for 4 minutes → Scale In
```

### Memory Alarms (CWAgent)
```
{asg_name}-memory-high: Memory >= 80% for 4 minutes → Scale Out
{asg_name}-memory-low:  Memory <= 50% for 6 minutes → Scale In (Test demo, thực tế nên để cao hơn)
```

### Disk Alarms (CWAgent)
```
{asg_name}-disk-high: Disk >= 80% for 4 minutes → Scale Out
```

### Composite Alarm
```
{asg_name}-scale-out-composite:
  IF cpu-high OR memory-high OR disk-high
  THEN Scale Out
```

## 🚀 Triển khai

### 1. IAM Permissions
Module `iam_module` đã được cập nhật với CloudWatch permissions:

```terraform
resource "aws_iam_role_policy" "ec2_cloudwatch_access" {
  # Cho phép:
  # - cloudwatch:PutMetricData
  # - ec2:DescribeVolumes
  # - logs:PutLogEvents
}
```

### 2. User Data Update
Các file script đã được cập nhật:
- ✅ `monitoring.sh` - Đã thêm CloudWatch Agent
- ⚠️ `ids.sh` - Đã thêm CloudWatch Agent
- ⚠️ `honey_pot.sh` - Đã thêm CloudWatch Agent
- ⚠️ `logs.sh` - Đã thêm CloudWatch Agent

### 3. Terraform Apply

```bash
cd create-monitoring-system
terraform plan
terraform apply
```

## 📊 Monitoring & Debugging

### Kiểm tra CloudWatch Agent Status

```bash
# SSH vào EC2 instance
ssh -i your-key.pem ubuntu@<instance-ip>

# Check agent status
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -m ec2 -a query

# View agent logs
sudo tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
```

### Xem Metrics trong CloudWatch Console

1. Vào **CloudWatch** → **Metrics** → **CWAgent**
2. Chọn **AutoScalingGroupName**
3. Xem metrics:
   - `mem_used_percent`
   - `disk_used_percent`

### Kiểm tra Alarms

```bash
# List all alarms
aws cloudwatch describe-alarms --alarm-name-prefix "asg-"

# Check alarm history
aws cloudwatch describe-alarm-history \
    --alarm-name "asg-monitoring-memory-high" \
    --max-records 10
```

## 🎛️ Tuning Thresholds

### Điều chỉnh ngưỡng scaling

Sửa trong `modules/asg_module/main.tf`:

```terraform
# CPU Thresholds
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  threshold = 70  # Thay đổi ngưỡng scale out
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  threshold = 50  # Thay đổi ngưỡng scale in
}

# Memory Thresholds
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  threshold = 80  # Memory scale out
}

# Disk Thresholds
resource "aws_cloudwatch_metric_alarm" "disk_high" {
  threshold = 85  # Disk scale out
}
```

### Điều chỉnh Cooldown Period

```terraform
resource "aws_autoscaling_policy" "scale_out_policy" {
  cooldown = 300  # Đợi 5 phút sau khi scale out
}

resource "aws_autoscaling_policy" "scale_in_policy" {
  cooldown = 300  # Đợi 5 phút sau khi scale in
}
```

## 🔍 Testing Scaling

### Test Memory-based Scaling

```bash
# SSH vào instance
ssh -i key.pem ubuntu@<ip>

# Tạo memory pressure
stress-ng --vm 2 --vm-bytes 80% --timeout 10m
```

### Test Disk-based Scaling

```bash
# Tạo file lớn để fill disk
dd if=/dev/zero of=/tmp/bigfile bs=1M count=10000
```

### Monitor Scaling Activity

```bash
# Xem ASG activities
aws autoscaling describe-scaling-activities \
    --auto-scaling-group-name asg-monitoring \
    --max-records 5
```

## ⚠️ Best Practices

1. **Cooldown Period**: Đặt cooldown >= 300s để tránh flapping
2. **Scale In Conservative**: Threshold thấp hơn và evaluation period dài hơn
3. **Monitor CloudWatch Costs**: CWAgent metrics tính phí theo số metrics
4. **Disk Monitoring**: Chỉ monitor filesystem quan trọng (ext4, xfs)
5. **Test Thoroughly**: Test scaling trước khi deploy production

## 💰 Cost Considerations

**CloudWatch Custom Metrics Pricing:**
- First 10,000 metrics: $0.30/metric/month
- Next 240,000 metrics: $0.10/metric/month

**Số metrics mỗi instance:**
- Memory: 3 metrics
- Disk: 2 metrics/filesystem
- Total: ~5-10 metrics/instance

**Example Cost:**
- 10 instances x 8 metrics = 80 metrics
- Cost: 80 x $0.30 = $24/month

## 🐛 Troubleshooting

### Metrics không xuất hiện trong CloudWatch

```bash
# 1. Check agent status
sudo systemctl status amazon-cloudwatch-agent

# 2. Check config
sudo cat /opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json

# 3. Restart agent
sudo systemctl restart amazon-cloudwatch-agent

# 4. Check IAM permissions
aws sts get-caller-identity
```

### Scale Out không trigger

```bash
# 1. Verify alarm state
aws cloudwatch describe-alarms \
    --alarm-names "asg-monitoring-scale-out-composite"

# 2. Check metrics data
aws cloudwatch get-metric-statistics \
    --namespace CWAgent \
    --metric-name mem_used_percent \
    --dimensions Name=AutoScalingGroupName,Value=asg-monitoring \
    --start-time 2025-12-11T00:00:00Z \
    --end-time 2025-12-11T23:59:59Z \
    --period 300 \
    --statistics Average
```

### Scale In quá nhanh

Tăng evaluation period và cooldown:

```terraform
resource "aws_cloudwatch_metric_alarm" "memory_low" {
  evaluation_periods = 5  # Tăng từ 3 lên 5
  period            = 300 # Giữ nguyên 5 phút
}

resource "aws_autoscaling_policy" "scale_in_policy" {
  cooldown = 600  # Tăng từ 5 phút lên 10 phút
}
```

## 📚 References

- [CloudWatch Agent Configuration](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html)
- [Auto Scaling Dynamic Scaling](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scale-based-on-demand.html)
- [CloudWatch Composite Alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Create_Composite_Alarm.html)
