# KLTN-MLOps-Network-Traffic-Detection
> Đây là repo chứa mã nguồn về IaC (Terraform) để tạo ra **Hạ tầng**, **Hệ thống IDs agent**, **Hệ thống monitoring** và **Hệ thống log**. Đảm bảo trước khi thực hiện phải cài **aws cli** và **terraform cli**. Dưới đây là cách để chạy được mã nguồn:
Kiểm tra version của các dịch vụ
``` bash
  aws --version
  terraform --version
```
## 1. Tạo S3 bucket và Scret
- Di chuyển vào thư mục `create-s3tfstate-secret`
``` bash
  cd create-s3tfstate-secret
```
- Chạy lần lượt các lệnh sau:
``` bash
  terraform init
  teraform plan
  terraform apply
```

## 2. Tạo hạ tầng (VPC, subnet, Security group,...)
- Di chuyển vào thư mục `create-infrastructure`
``` bash
  cd create-infrastructure
```
- Chạy lần lượt các lệnh
``` bash
  terraform init
  teraform plan
  terraform apply
```

## 3. Tạo hệ thống IDS agent
- Di chuyển vào thư mục `create-ids-agent-system`
``` bash
  cd create-ids-agent-system
```
- Chạy lần lượt các lệnh
``` bash
  terraform init
  teraform plan
  terraform apply
```

## 4. Tạo hệ thống giám sát (monitoring)
- Di chuyển vào thư mục `create-monitoring-system`
``` bash
  cd create-monitoring-system
```
> Vì hiện tại chỉ dùng AWS route53 để host tên miền tạm, nên cần chỉnh file `./script/monitoring.sh`
- Thay đổi `targets` bằng ALB của IDS mỗi lần apply nếu ALB IDS thay đổi, ví dụ:
``` yml
  scrape_configs:
  - job_name: 'ids-node'
    metrics_path: /metrics
    scheme: http
    static_configs: 
      - targets: ["alb-ids-1001117453.us-east-1.elb.amazonaws.com"]   # ALB IDS (HTTP 80 → 9100), thay đổi sau mỗi lần apply
        labels:
          app: "ids_node"
```
- Chạy lần lượt các lệnh
``` bash
  terraform init
  teraform plan
  terraform apply
```
- Truy cập `http://monitoring.qm.uit/prometheus` để truy cập prometheus. Chọn `target health` trong **Prometheus** để kiểm tra target `node_exporter`.
- Truy cập `http://monitoring.qm.uit` để truy cập grafana với tài khoản mặc định `admin/admin`. Thêm **Data source**, chọn **Prometheus**, thêm đường dẫn `http://<alb-monitoring>/prometheus`. sau đó chọn `Save & Test`.
- Import dashboard với ID: **1860**, data source là `prometheus` với thêm vào.

## 5. Triển khai ứng dụng giám sát log (hệ thống log)
