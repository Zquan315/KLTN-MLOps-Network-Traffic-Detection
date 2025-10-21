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
### 1. Tạo S3 Bucket 
- **Mục đích:** Tạo một S3 bucket để lưu trữ trạng thái Terraform (Terraform state)
- Trên giao diện console, vào **S3**, tạo một bucket với tên **"terraform-state-bucket-9999** (tùy chỉnh, nếu tên khác thì vào các file **main.tf** chỉnh lại tên bucket).
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
- **Mục đích:** Thiết lập hệ thống giám sát sử dụng Prometheus và Grafana để thu thập và trực qulog-system
```
- Chạy các lệnh Terraform:
``` bash
terraform init
terraform plan
terraform apply
```
- Vì hiện tại domain rote53 chỉ hoạt động ở local máy, vì thế cần dùng phương pháp add host.
  - Trên console của AWS, vào EC2, lướt xuống chọn **load balancer**.
  - Chọn **alb-logs**, copy DNS của nó và dùng **nslookup** để resovle ra ip public của nó.
  - Mở file **.../etc/hosts** với quyền Admin trên windows, thêm **<IP_public>  <Tên domain>**, lưu lại.
  - Truy cập web: http://<tên domain>/, sẽ xuất hiện giao diện web. Cụ thể hệ thống **http://logs.qm.uit/**
