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
### 1. Tạo các service ban đầu
#### 1.1. Tạo S3 Bucket 
- **Mục đích:** Tạo một S3 bucket để lưu trữ trạng thái Terraform (Terraform state)
- Trên giao diện console, vào **S3**, tạo một bucket với tên **"terraform-state-bucket-9999** (tùy chỉnh, nếu tên khác thì vào các file **main.tf** chỉnh lại tên bucket).
---
#### 1.2. Tạo Identities (Email) 
- **Mục đích:** IDS có thể gửi cảnh báo khi chuyển traffic tấn công qua honeypot
- Trên giao diện console, vào **Simple Email Service (SES)**, tab **configuration** chọn **Identities**. Tiếp đó tạo một **Identities**, nhập email muốn gửi và nhận và xác thực.
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

### 3. Tạo hệ thống Honeypot (**Chưa test hoàn thiện, đừng chạy**)
- **Thư mục:** `create-honey-pot-system`
- **Mục đích:** Triển khai các server honeypot để "thu hút" lưu lượng **attack** từ IDS agent
- Di chuyển vào thư mục `create-honey-pot-system`
``` bash
cd create-honey-pot-system
```
- Chạy các lệnh Terraform:
``` bash
terraform init
terraform plan
terraform apply
```
---
### 4. Tạo hệ thống IDS Agent
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
### 5. Tạo hệ thống giám sát
- **Thư mục:** `create-monitoring-system`
- **Mục đích:** Thiết lập hệ thống giám sát sử dụng Prometheus và Grafana để thu thập và trực quan hóa các metrics từ IDS agent.
- Di chuyển vào thư mục `create-monitoring-system`
``` bash
cd create-monitoring-system
```
- Vì hiện tại chỉ dùng AWS route53 để host tên miền tạm, nên cần chỉnh file `./script/monitoring.sh`
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
---
### 6. Triển khai hệ thống quản lý log
- **Thư mục:** `create-log-system`
- **Mục đích:** Triển khai ứng dụng web để truy xuất và quản lý log database mà IDS agent đẩy về.
- Di chuyển vào thư mục `create-log-system`
``` bash
cd create-log-system
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
  - Mở file **.../etc/hosts** với quyền Admin trên windows, thêm **<IP public>  <Tên domain>**, lưu lại.
  - Truy cập web: http://<tên domain>/, sẽ xuất hiện giao diện web. Cụ thể hệ thống **http://logs.qm.uit/**
---
