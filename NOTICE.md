# Dưới đây là nhưng lưu ý. Vì tui đã thêm code cho test về redirect to honey pot. Nên có tạo mới code, tuy nhiên chưa test chắc chắn nên sẽ command lại một số phần.

- Các command trong infrastructure
- Các command trong ids-agent-system
- script mới bằng cách thay 65 bằng 64 (đang command) trong ids.sh
``` bash
    #sudo HONEYPOT_ALB_URL="${HONEYPOT_ALB_URL}" SQS_QUEUE_URL="${SQS_QUEUE_URL}" python3 application.py
```
- Cập nhật Logic application.py từ repo ids-ingress-predict.git như sau (Chưa thay đổi code trên github)

``` python
# ... (các import giữ nguyên) ...

# ============================================================
# Flask + SocketIO Setup
# ============================================================
app = Flask(__name__)
# ... (giữ nguyên) ...

# ============================================================
# Logging
# ============================================================
# ... (giữ nguyên) ...

# ============================================================
# Config
# ============================================================
ec2_api_ip = os.getenv("EC2_API_IP")
MODEL_API_URL = f"http://{ec2_api_ip}/predict"
AWS_REGION = "us-east-1"

# === 1. THÊM VÀO ĐÂY: Honeypot & SQS Config ===
HONEYPOT_ALB_URL = os.environ.get('HONEYPOT_ALB_URL')
SQS_QUEUE_URL = os.environ.get('SQS_QUEUE_URL')

if not HONEYPOT_ALB_URL:
    logging.warning("Biến môi trường HONEYPOT_ALB_URL chưa được set!")
if not SQS_QUEUE_URL:
    logging.warning("Biến môi trường SQS_QUEUE_URL chưa được set!")
# === KẾT THÚC THÊM 1 ===


# ============================================================
# DynamoDB Setup
# ============================================================
try:
    dynamodb = boto3.resource("dynamodb", region_name=AWS_REGION)
    table = dynamodb.Table("ids_log_system")
    logging.info("Connected to DynamoDB")
except Exception as e:
    table = None
    logging.error(f"DynamoDB init failed: {e}")

# === 2. THÊM VÀO ĐÂY: SQS Client Setup ===
try:
    sqs_client = boto3.client('sqs', region_name=AWS_REGION)
    logging.info("Connected to SQS")
except Exception as e:
    sqs_client = None
    logging.error(f"SQS client init failed: {e}")
# === KẾT THÚC THÊM 2 ===

# ============================================================
# Thread-safe cache
# ============================================================
# ... (giữ nguyên) ...
```

``` python
# ============================================================
# Process flow
# ============================================================
def process_incoming_flow(payload):
    # Làm sạch toàn bộ features
    features = {c: safe(payload.get(c, 0)) for c in FEATURE_COLUMNS}

    # Dọn dẹp lại toàn bộ giá trị NaN/Inf nếu có
    for k, v in features.items():
        if isinstance(v, float) and (math.isnan(v) or math.isinf(v)):
            logging.debug(f"[CLEAN] Replaced invalid value {v} for {k} -> 0.0")
            features[k] = 0.0

    # Gửi đi dự đoán
    label, conf = predict_features_api(features)

    result = {
        "flow_id": payload.get("Flow ID", ""),
        "src_ip": payload.get("Source IP", ""),
        "dst_ip": payload.get("Destination IP", ""),
        "src_port": payload.get("Source Port", ""),
        "dst_port": payload.get("Destination Port", ""),
        "protocol": payload.get("Protocol", ""),
        "timestamp": payload.get("Timestamp", datetime.now().strftime("%Y-%m-%d %H:%M:%S")),
        "timestamp_ms": to_timestamp_ms(payload.get("Timestamp", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))),
        "binary_prediction": label,
        "binary_confidence": conf,
        "features": features,
    }

    with flow_results_lock:
        flow_results.append(result)
        if len(flow_results) > 1000:
            flow_results.pop(0)

    try:
        socketio.emit("new_flow", result)
        eventlet.sleep(0)
    except Exception:
        logging.exception("SocketIO emit failed")

    # === 3. THÊM LOGIC MỚI TẠI ĐÂY ===
    # (Trước khi ghi log DynamoDB)
    
    # Biến 'label' đã có sẵn
    if label == 'attack':
        logging.info(f"ATTACK DETECTED: Forwarding flow_id={result['flow_id']} to honeypot...")
        
        # 'payload' chính là JSON gốc từ csv_playback.py
        # Chúng ta dùng nó làm 'attack_payload'
        attack_payload = payload 
        
        # 5.1. Chuyển tiếp (Forward) đến Honeypot
        if HONEYPOT_ALB_URL:
            try:
                # Dùng httpx (giống code predict_features_api) thay vì requests
                # Gửi payload tấn công đến honeypot
                # đặt timeout ngắn để không làm chậm IDS
                httpx.post(HONEYPOT_ALB_URL, json=attack_payload, timeout=2.0)
                logging.info("Successfully forwarded attack to honeypot.")
            except Exception as e:
                logging.error(f"Lỗi: Không thể chuyển tiếp đến honeypot: {e}")
        
        # 5.2. Gửi tin nhắn cảnh báo (cho Lambda xử lý gộp)
        if sqs_client and SQS_QUEUE_URL:
            try:
                # Gửi 1 tin nhắn vào SQS, Lambda sẽ nhận và gộp lại
                sqs_client.send_message(
                    QueueUrl=SQS_QUEUE_URL,
                    MessageBody=json.dumps(attack_payload) # Gửi payload làm bằng chứng
                )
                logging.info("Successfully sent alert message to SQS.")
            except Exception as e:
                logging.error(f"Lỗi: Không thể gửi tin nhắn SQS: {e}")

    # === KẾT THÚC THÊM 3 ===

    # Bây giờ mới ghi log vào DynamoDB (bất kể là attack hay benign)
    log_to_dynamodb_async(result)
    return result
```