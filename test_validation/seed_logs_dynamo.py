import boto3
import uuid
import time
import random
import json
from decimal import Decimal

# ==========================================
# CẤU HÌNH
# ==========================================
TABLE_NAME = 'ids_log_system'  # Tên bảng bạn đã define trong Terraform
REGION = 'us-east-1'           # Region bạn đang deploy
TOTAL_ITEMS = 1000              # Số lượng cần thêm (3 cũ + 997 mới = 1000)

# Khởi tạo DynamoDB Resource
dynamodb = boto3.resource('dynamodb', region_name=REGION)
table = dynamodb.Table(TABLE_NAME)

# Dữ liệu giả lập
LABELS = ['benign', 'attack']
ATTACK_TYPES = ['SSH Brute Force', 'SQL Injection', 'DDoS', 'XSS Attempt']
NORMAL_TYPES = ['HTTP Browsing', 'SMTP Mail', 'DNS Query', 'NTP Sync']

def generate_random_ip():
    return f"192.168.{random.randint(1, 255)}.{random.randint(1, 255)}"

def create_dummy_item():
    # 1. Random Label
    label = random.choice(LABELS)
    
    # 2. Random Content based on label
    src_ip = generate_random_ip()
    dst_ip = "10.0.0.5" # Giả sử đây là server của bạn
    
    if label == 'attack':
        desc = random.choice(ATTACK_TYPES)
        color_log = f"Src: {src_ip} -> {dst_ip} [ALERT: {desc}]"
        packet_count = random.randint(500, 5000)
    else:
        desc = random.choice(NORMAL_TYPES)
        color_log = f"Src: {src_ip} -> {dst_ip} ({desc})"
        packet_count = random.randint(5, 50)

    # 3. Features JSON (Stringified JSON)
    features = {
        "Flow Duration": round(random.uniform(0.1, 5.0), 2),
        "Total Fwd Packets": packet_count,
        "Total Bwd Packets": random.randint(0, 10),
        "Protocol": random.choice(["TCP", "UDP", "ICMP"])
    }

    # 4. Timestamp: Rải rác trong 24h qua
    # Terraform define 'type = "N"', boto3 sẽ tự map int/decimal sang N
    current_ms = int(time.time() * 1000)
    offset = random.randint(0, 86400 * 1000) # Random trong 1 ngày
    ts = current_ms - offset

    return {
        'flow_id': str(uuid.uuid4()),      # Hash Key (S)
        'timestamp': ts,                   # Range Key (N)
        'label': label,                    # GSI Hash Key (S)
        'content': color_log,              # GSI Hash Key (S)
        'features_json': json.dumps(features) # Attribute (S)
    }

def main():
    print(f"Bắt đầu nạp {TOTAL_ITEMS} bản ghi vào bảng '{TABLE_NAME}'...")
    start_time = time.time()

    # Sử dụng batch_writer để ghi nhanh hơn
    with table.batch_writer() as batch:
        for i in range(TOTAL_ITEMS):
            item = create_dummy_item()
            batch.put_item(Item=item)
            
            if (i + 1) % 100 == 0:
                print(f"Da ghi {i + 1} items...")

    end_time = time.time()
    print(f"\n[OK] Đã nạp xong {TOTAL_ITEMS} items.")
    print(f"Thời gian thực hiện: {end_time - start_time:.2f} giây")

    # Verify count (Lưu ý: Scan count có thể bị delay update khoảng 6 tiếng trong AWS Console, 
    # nhưng query thực tế sẽ thấy ngay)
    print("\nKiểm tra lại số lượng (Approx):")
    try:
        print(f"Table Item Count: {table.item_count} (Lưu ý: Dữ liệu này update chậm trên AWS)")
    except:
        pass

if __name__ == '__main__':
    main()