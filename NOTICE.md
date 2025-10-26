# Dưới đây là nhưng lưu ý. Vì tui đã thêm code cho test về redirect to honey pot. Nên có tạo mới code, tuy nhiên chưa test chắc chắn nên sẽ command lại một số phần.

- Các command trong infrastructure
- Các command trong ids-agent-system
- script mới bằng cách thay 65 bằng 64 (đang command) trong ids.sh
- Cập nhật Logic application.py từ repo ids-ingress-predict.git như sau (Chưa thay đổi code trên github)

``` python
# --- Thêm vào đầu file (cùng các import khác) ---
import os
import boto3
import json
import requests # Đảm bảo đã import

# --- Thêm vào sau khi khởi tạo 'app = Flask(__name__)' ---
# 1. Khởi tạo AWS clients
try:
    sqs_client = boto3.client('sqs', region_name='us-east-1')
except Exception as e:
    print(f"Lỗi: Không thể khởi tạo SQS client. Đã cài boto3 chưa? {e}")
    sqs_client = None

# 2. Lấy URL từ biến môi trường
HONEYPOT_ALB_URL = os.environ.get('HONEYPOT_ALB_URL')
SQS_QUEUE_URL = os.environ.get('SQS_QUEUE_URL')

if not HONEYPOT_ALB_URL:
    print("CẢNH BÁO: Biến môi trường HONEYPOT_ALB_URL chưa được set!")
if not SQS_QUEUE_URL:
    print("CẢNH BÁO: Biến môi trường SQS_QUEUE_URL chưa được set!")

# --- Tìm hàm xử lý request (ví dụ: hàm @app.route('/predict') hoặc hàm gọi predict_and_log) ---
# Bên trong hàm mà bạn nhận được 'label' (ví dụ: sau dòng `label = response.json().get('prediction')`)

# ...
# Giả sử bạn có biến 'label' (là 'attack' hoặc 'benign')
# và 'flow_json' (là JSON của request gốc từ csv_playback.py)
# ...

# 4. GHI LOG VÀO DYNAMODB (Code này bạn đã có)
# ...
# db.log_flow(flow_id, timestamp, content, label, features_json)
# ...

# 5. THÊM LOGIC MỚI: CHUYỂN TIẾP VÀ CẢNH BÁO NẾU LÀ ATTACK
if label == 'attack':
    print(f"ATTACK DETECTED: Forwarding to honeypot and sending alert...")
    
    # Lấy toàn bộ JSON gốc mà csv_playback.py đã gửi
    # (Tôi giả định nó được lưu trong biến 'flow_json' hoặc 'request_data')
    # Nếu bạn chưa có, bạn cần lấy nó từ 'request.get_json()' ở đầu hàm
    attack_payload = flow_json # <--- ĐẢM BẢO 'flow_json' là JSON gốc
    
    # 5.1. Chuyển tiếp (Forward) đến Honeypot
    if HONEYPOT_ALB_URL:
        try:
            # Gửi payload tấn công đến honeypot
            # đặt timeout ngắn để không làm chậm IDS
            requests.post(HONEYPOT_ALB_URL, json=attack_payload, timeout=2)
            print("Successfully forwarded attack to honeypot.")
        except Exception as e:
            print(f"Lỗi: Không thể chuyển tiếp đến honeypot: {e}")
    
    # 5.2. Gửi tin nhắn cảnh báo (cho Lambda xử lý gộp)
    if sqs_client and SQS_QUEUE_URL:
        try:
            # Gửi 1 tin nhắn vào SQS, Lambda sẽ nhận và gộp lại
            sqs_client.send_message(
                QueueUrl=SQS_QUEUE_URL,
                MessageBody=json.dumps(attack_payload) # Gửi payload làm bằng chứng
            )
            print("Successfully sent alert message to SQS.")
        except Exception as e:
            print(f"Lỗi: Không thể gửi tin nhắn SQS: {e}")

# 6. TRẢ VỀ RESPONSE CHO CLIENT (Code này bạn đã có)
# ...
# return jsonify({"status": "logged", "label": label})
# ...
```