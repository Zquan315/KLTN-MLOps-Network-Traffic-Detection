# KLTN-MLOps-Network-Traffic-Detection
Đây là repository chứa mã nguồn sử dụng Terraform (Infrastructure as Code - IaC) để triển khai hạ tầng trên AWS cho hệ thống phát hiện lưu lượng mạng bất thường. Dự án bao gồm các thành phần để tạo S3 bucket, secrets, hạ tầng mạng (VPC, subnet, security group), hệ thống IDS (Intrusion Detection System) agent, và hệ thống giám sát sử dụng Prometheus và Grafana.
## Trước khi chạy mã nguồn, hãy đảm bảo đã cài đặt và cấu hình các công cụ sau:

- AWS CLI: Công cụ dòng lệnh để tương tác với các dịch vụ AWS.
- Terraform CLI: Công cụ để quản lý hạ tầng dưới dạng mã nguồn.

Kiểm tra phiên bản của các công cụ:

``` bash
aws --version
terraform --version
```
## Hướng dẫn triển khai
### 1. Tạo S3 Bucket và Secrets
- **Thư mục:** `create-s3tfstate`
- **Mục đích:** Tạo một S3 bucket để lưu trữ trạng thái Terraform (Terraform state) và quản lý các bí mật (secrets).
- Di chuyển vào thư mục `create-s3tfstate`:
``` bash
cd create-s3tfstate
```
  - Chạy các lệnh Terraform:
``` bash
terraform init
terraform plan
terraform apply
```
---
### 2. Tạo hạ tầng (VPC, Subnet, Security Group, API Instance)
- **Thư mục:** `create-infrastructure`
- **Mục đích:** Triển khai hạ tầng mạng, bao gồm VPC, subnet, security group, một API instance và một Elastic IP để IDS agent giao tiếp với API.
- Di chuyển vào thư mục `create-infrastructure`
``` bash
cd create-infrastructure
```
- Chạy các lệnh Terraform:
``` bash
terraform init
terraform plan
terraform apply
```
---
### 3. Tạo hệ thống IDS Agent
- **Thư mục:** `create-ids-agent-system`
- **Mục đích:** Triển khai các IDS agent để phát hiện và phân tích lưu lượng mạng bất thường.
- Di chuyển vào thư mục `create-ids-agent-system`
``` bash
cd create-ids-agent-system
```
- Chạy các lệnh Terraform:
``` bash
terraform init
terraform plan
terraform apply
```
---
### 4. Tạo hệ thống giám sát
- **Thư mục:** `create-monitoring-system`
- **Mục đích:** Thiết lập hệ thống giám sát sử dụng Prometheus và Grafana để thu thập và trực quan hóa các metrics từ IDS agent.
- Di chuyển vào thư mục `create-monitoring-system`
``` bash
cd create-monitoring-system
```
- Vì hiện tại chỉ dùng AWS route53 để host tên miền tạm, nên cần chỉnh file `./script/monitoring.sh`
- Cập nhật trường targets trong file ./script/monitoring.sh với địa chỉ Application Load Balancer (ALB) của hệ thống IDS. Ví dụ:
``` yml
scrape_configs:
- job_name: 'ids-node'
  metrics_path: /metrics
  scheme: http
  static_configs: 
    - targets: ["alb-ids-1001117453.us-east-1.elb.amazonaws.com"]   # Cập nhật địa chỉ ALB sau mỗi lần apply
      labels:
        app: "ids_node"
```
- Chạy các lệnh Terraform:
``` bash
terraform init
terraform plan
terraform apply
```
- Truy cập hệ thống giám sát:
  - Prometheus: Truy cập tại `http://monitoring.qm.uit/prometheus`. Kiểm tra trạng thái các target trong mục Target Health.
  - Grafana: Truy cập tại `http://monitoring.qm.uit` với tài khoản mặc định admin/admin. Thêm **Data source**, chọn **Prometheus**, thêm đường dẫn `http://<alb-monitoring>/prometheus`. sau đó chọn `Save & Test`.
  - Import dashboard với ID: **1860**, Data Source là `Prometheus` với thêm vào.

