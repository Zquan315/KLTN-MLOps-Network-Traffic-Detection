import requests
import time
import concurrent.futures
import statistics
import urllib3

# Tắt cảnh báo SSL nếu chưa cài chứng chỉ xịn
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# ==========================================
# CẤU HÌNH TEST
# ==========================================
# URL API của bạn (đảm bảo đúng protocol http hoặc https)
BASE_URL = "http://logs.qmuit.id.vn/api" 
USERNAME = "admin"
PASSWORD = "admin123"

# Số lượng người dùng giả lập cùng lúc (Concurrent Users)
CONCURRENT_USERS = 1000

# Số lần lặp lại request cho mỗi user (để bài test chạy lâu hơn chút)
REQUESTS_PER_USER = 50

class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def print_header(text):
    print(f"\n{Colors.HEADER}{Colors.BOLD}=== {text} ==={Colors.ENDC}")

# ---------------------------------------------------------
# 1. LOGIN (Lấy Token Admin dùng chung)
# ---------------------------------------------------------
def login():
    print(f"[*] Đang đăng nhập user: {USERNAME}...")
    try:
        res = requests.post(
            f"{BASE_URL}/auth/login", 
            json={"username": USERNAME, "password": PASSWORD}, 
            verify=False
        )
        if res.status_code in [200, 201]:
            print(f"{Colors.OKGREEN}[✓] Đăng nhập thành công!{Colors.ENDC}")
            return res.json()['accessToken']
        else:
            print(f"{Colors.FAIL}[!] Đăng nhập thất bại: {res.text}{Colors.ENDC}")
            exit(1)
    except Exception as e:
        print(f"{Colors.FAIL}[!] Lỗi kết nối: {e}{Colors.ENDC}")
        exit(1)

# ---------------------------------------------------------
# 2. HÀM GỌI API (WORKER)
# ---------------------------------------------------------
def worker_task(token):
    headers = {"Authorization": f"Bearer {token}"}
    session_latencies = []
    error_count = 0
    
    # Mỗi user ảo sẽ gọi API vài lần
    for _ in range(REQUESTS_PER_USER):
        start = time.time()
        try:
            # Giả lập load Dashboard (Lấy 100 dòng log mới nhất)
            res = requests.get(
                f"{BASE_URL}/logs?limit=100", 
                headers=headers, 
                verify=False, 
                timeout=10 # Timeout 10s
            )
            duration = (time.time() - start) * 1000 # ms
            
            if res.status_code == 200:
                session_latencies.append(duration)
            else:
                error_count += 1
        except Exception:
            error_count += 1
            
    return session_latencies, error_count

# ---------------------------------------------------------
# 3. CHẠY TEST CHỊU TẢI
# ---------------------------------------------------------
def run_stress_test(token):
    print_header(f"BÀI TEST 2: KIỂM THỬ CHỊU TẢI (STRESS TEST)")
    print(f"• Mục tiêu:  Đánh giá hiệu năng AWS ALB & NestJS Backend")
    print(f"• Kịch bản:  {CONCURRENT_USERS} người dùng truy cập cùng lúc.")
    print(f"• Tổng cộng: {CONCURRENT_USERS * REQUESTS_PER_USER} requests.")
    print("-" * 60)
    print(f"[*] Đang gửi requests vào hệ thống... Vui lòng chờ đợi....")

    all_latencies = []
    total_errors = 0
    start_time = time.time()

    # Sử dụng ThreadPool để bắn request song song
    with concurrent.futures.ThreadPoolExecutor(max_workers=CONCURRENT_USERS) as executor:
        futures = [executor.submit(worker_task, token) for _ in range(CONCURRENT_USERS)]
        
        for future in concurrent.futures.as_completed(futures):
            lats, errs = future.result()
            all_latencies.extend(lats)
            total_errors += errs

    total_duration = time.time() - start_time
    total_requests = len(all_latencies) + total_errors
    rps = total_requests / total_duration if total_duration > 0 else 0

    # ---------------------------------------------------------
    # BÁO CÁO KẾT QUẢ
    # ---------------------------------------------------------
    print(f"\n{Colors.OKBLUE}>>> KẾT QUẢ TEST 2:{Colors.ENDC}")
    
    # 1. Tỷ lệ thành công
    success_rate = (len(all_latencies) / total_requests * 100) if total_requests > 0 else 0
    if total_errors == 0:
        print(f"   - Trạng thái:         {Colors.OKGREEN}THÀNH CÔNG TUYỆT ĐỐI (100%){Colors.ENDC}")
    else:
        print(f"   - Trạng thái:         {Colors.WARNING}CÓ LỖI ({success_rate:.1f}% Success){Colors.ENDC}")
        print(f"   - Số request lỗi:     {Colors.FAIL}{total_errors}{Colors.ENDC}")

    # 2. Thông lượng (Throughput)
    print(f"   - Thời gian test:     {total_duration:.2f} giây")
    print(f"   - Tổng request:       {total_requests}")
    print(f"   - Thông lượng (RPS):  {Colors.BOLD}{rps:.2f} Req/s{Colors.ENDC}")

    # 3. Độ trễ (Latency)
    if all_latencies:
        avg_lat = statistics.mean(all_latencies)
        max_lat = max(all_latencies)
        min_lat = min(all_latencies)
        
        print(f"   - Độ trễ trung bình:  {Colors.OKGREEN}{avg_lat:.2f} ms{Colors.ENDC}")
        print(f"   - Nhanh nhất (Min):   {min_lat:.2f} ms")
        print(f"   - Chậm nhất (Max):    {max_lat:.2f} ms")
    
    print("-" * 60)
    if rps > 100 and total_errors == 0:
        print(f"{Colors.OKGREEN}✔ NHẬN XÉT: Hệ thống chịu tải TỐT. ALB phân phối tải hiệu quả.{Colors.ENDC}")
    else:
        print(f"{Colors.WARNING}⚠ NHẬN XÉT: Cần kiểm tra lại tài nguyên Server.{Colors.ENDC}")

# ==========================================
# MAIN
# ==========================================
if __name__ == "__main__":
    token = login()
    run_stress_test(token)