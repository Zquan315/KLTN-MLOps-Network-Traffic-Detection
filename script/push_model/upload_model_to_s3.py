#!/usr/bin/env python3
"""
upload_model_to_s3.py
----------------------------------------
Tự động upload tất cả file model (*.pkl) trong thư mục ./models
lên S3 bucket (theo version bạn nhập hoặc mặc định là 'v1.0').
"""

import boto3
from pathlib import Path

# ============================================================
# ⚙️ Cấu hình
# ============================================================
BUCKET_NAME = "arf-ids-model-bucket"   # đổi nếu cần
MODEL_VERSION = input("🔢 Nhập version (mặc định = v1.0): ") or "v1.0"

# Thư mục hiện tại + models/
base_dir = Path(__file__).resolve().parent
models_dir = base_dir / "models"

if not models_dir.exists():
    print(f"❌ Không tìm thấy thư mục models/ trong {base_dir}")
    exit(1)

# Lấy tất cả file trong models/ (đặc biệt *.pkl)
files = [f for f in models_dir.glob("*") if f.is_file()]

if not files:
    print("⚠️ Không có file nào trong thư mục models/.")
    exit(0)

s3 = boto3.client("s3")

# ============================================================
# 🚀 Upload từng file lên S3
# ============================================================
for f in files:
    s3_key = f"{MODEL_VERSION}/{f.name}"
    try:
        print(f"⬆️ Uploading {f.name} → s3://{BUCKET_NAME}/{s3_key}")
        s3.upload_file(str(f), BUCKET_NAME, s3_key)
        print(f"✅ Uploaded successfully: s3://{BUCKET_NAME}/{s3_key}")
    except Exception as e:
        print(f"❌ Failed to upload {f.name}: {e}")

print(f"\n🎯 Done! Uploaded {len(files)} files from '{models_dir}' to s3://{BUCKET_NAME}/{MODEL_VERSION}/")
