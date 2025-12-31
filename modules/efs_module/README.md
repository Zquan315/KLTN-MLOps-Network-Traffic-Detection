# EFS Module for Monitoring Data Persistence

## Mô tả

Module này tạo AWS EFS (Elastic File System) để lưu trữ dữ liệu Prometheus, Grafana và Alertmanager một cách bền vững (persistent). Khi các EC2 instances trong Auto Scaling Group bị terminated hoặc scale, dữ liệu sẽ không bị mất.

## Tính năng

- **EFS File System**: Tạo shared file system với encryption
- **Mount Targets**: Tự động tạo mount targets trong các subnets được chỉ định
- **Access Points**: Tạo separate access points cho từng service:
  - Prometheus (UID/GID: 65534)
  - Grafana (UID/GID: 472)
  - Alertmanager (UID/GID: 65534)
- **Security Group**: Tích hợp với security group module để kiểm soát NFS traffic

## Kiến trúc

```
┌─────────────────────────────────────────────────────┐
│                     VPC                              │
│                                                      │
│  ┌──────────────┐        ┌──────────────┐          │
│  │  Subnet 1    │        │  Subnet 2    │          │
│  │              │        │              │          │
│  │  ┌────────┐  │        │  ┌────────┐  │          │
│  │  │ Mount  │  │        │  │ Mount  │  │          │
│  │  │ Target │◄─┼────────┼─►│ Target │  │          │
│  │  └───┬────┘  │        │  └───┬────┘  │          │
│  │      │       │        │      │       │          │
│  │  ┌───▼───────┴────────┴──────▼─────┐ │          │
│  │  │        EFS File System          │ │          │
│  │  │                                 │ │          │
│  │  │  /prometheus    (AP: 65534)    │ │          │
│  │  │  /grafana       (AP: 472)      │ │          │
│  │  │  /alertmanager  (AP: 65534)    │ │          │
│  │  └─────────────────────────────────┘ │          │
│  │                                       │          │
│  │  ┌──────────────────────────┐        │          │
│  │  │  Monitoring EC2 Instance │        │          │
│  │  │  (Auto Scaling Group)    │        │          │
│  │  │                          │        │          │
│  │  │  /mnt/efs (NFS mount)   │        │          │
│  │  │  ├─ /prometheus          │        │          │
│  │  │  ├─ /grafana             │        │          │
│  │  │  └─ /alertmanager        │        │          │
│  │  └──────────────────────────┘        │          │
│  └──────────────────────────────────────┘          │
└─────────────────────────────────────────────────────┘
```

## Sử dụng

### 1. Tạo Infrastructure với EFS

```bash
cd create-infrastructure
terraform init
terraform plan
terraform apply
```

Module EFS sẽ được tạo tự động với:
- EFS file system với encryption
- Mount targets trong public subnets (nơi monitoring instances chạy)
- Security group cho phép NFS traffic (port 2049)
- Access points cho Prometheus, Grafana, và Alertmanager

### 2. Deploy Monitoring System

```bash
cd create-monitoring-system
terraform init
terraform plan
terraform apply
```

Monitoring instances sẽ tự động:
- Mount EFS filesystem tới `/mnt/efs`
- Bind mount các thư mục service:
  - `/mnt/efs/prometheus` → `/opt/monitoring/prometheus_data`
  - `/mnt/efs/grafana` → `/opt/monitoring/grafana_data`
  - `/mnt/efs/alertmanager` → `/opt/monitoring/alertmanager_data`

### 3. Kiểm tra EFS mount trên EC2

SSH vào monitoring instance và kiểm tra:

```bash
# Kiểm tra mount points
df -h | grep efs

# Kiểm tra thư mục dữ liệu
ls -la /mnt/efs/
ls -la /opt/monitoring/prometheus_data/
ls -la /opt/monitoring/grafana_data/
ls -la /opt/monitoring/alertmanager_data/

# Kiểm tra fstab
cat /etc/fstab | grep efs
```

## Outputs

Module EFS expose các outputs sau:

- `efs_id`: ID của EFS file system
- `efs_dns_name`: DNS name để mount EFS (format: `fs-xxxxx.efs.region.amazonaws.com`)
- `efs_arn`: ARN của EFS file system
- `prometheus_access_point_id`: ID của Prometheus access point
- `grafana_access_point_id`: ID của Grafana access point
- `alertmanager_access_point_id`: ID của Alertmanager access point

## Lợi ích

1. **Data Persistence**: Dữ liệu Prometheus, Grafana dashboards, và Alertmanager config được lưu trữ bền vững
2. **High Availability**: Dữ liệu được replicate tự động across multiple AZs
3. **Auto Scaling Safe**: Khi EC2 instances scale up/down hoặc bị terminated, dữ liệu vẫn an toàn
4. **Shared Storage**: Nhiều instances có thể truy cập cùng một EFS (useful khi scale monitoring)
5. **Easy Backup**: EFS có thể được backup tự động qua AWS Backup

## Security

- EFS được mã hóa at-rest và in-transit
- Security group chỉ cho phép NFS traffic (port 2049) từ monitoring instances
- Access points đảm bảo mỗi service chỉ access được thư mục của mình với đúng permissions

## Monitoring và Troubleshooting

### Kiểm tra EFS metrics trong CloudWatch

- `BurstCreditBalance`: Credits còn lại cho burst throughput
- `ClientConnections`: Số lượng connections
- `DataReadIOBytes`: Data đọc từ EFS
- `DataWriteIOBytes`: Data ghi vào EFS

### Common Issues

**Issue: Mount failed with "Connection timed out"**
- Kiểm tra security group cho phép port 2049
- Kiểm tra mount target có trong đúng subnet không

**Issue: Permission denied khi ghi file**
- Kiểm tra ownership của thư mục trên EFS
- Đảm bảo UID/GID match với service (Prometheus: 65534, Grafana: 472)

**Issue: Slow performance**
- Kiểm tra `BurstCreditBalance` trong CloudWatch
- Cân nhắc chuyển sang Provisioned Throughput mode

## Cost Optimization

- Sử dụng Lifecycle Policy để tự động move ít được truy cập sang IA storage class
- Xóa old Prometheus data (retention mặc định: 15 ngày)
- Monitor storage usage và optimize retention policies

## Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| efs_name | Name of the EFS file system | string | - |
| creation_token | Unique token for EFS creation | string | - |
| encrypted | Enable encryption | bool | true |
| performance_mode | Performance mode (generalPurpose/maxIO) | string | generalPurpose |
| throughput_mode | Throughput mode (bursting/provisioned/elastic) | string | bursting |
| subnet_ids | List of subnet IDs for mount targets | list(string) | - |
| security_group_ids | List of security group IDs | list(string) | - |
| prometheus_uid | UID for Prometheus user | number | 65534 |
| prometheus_gid | GID for Prometheus user | number | 65534 |
| grafana_uid | UID for Grafana user | number | 472 |
| grafana_gid | GID for Grafana user | number | 472 |
| alertmanager_uid | UID for Alertmanager user | number | 65534 |
| alertmanager_gid | GID for Alertmanager user | number | 65534 |

## Tham khảo

- [AWS EFS Documentation](https://docs.aws.amazon.com/efs/)
- [Mounting EFS on EC2](https://docs.aws.amazon.com/efs/latest/ug/mounting-fs.html)
- [EFS Access Points](https://docs.aws.amazon.com/efs/latest/ug/efs-access-points.html)
