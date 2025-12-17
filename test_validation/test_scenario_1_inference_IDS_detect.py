#!/usr/bin/env python3
"""
SCENARIO 1: END-TO-END ML INFERENCE LATENCY TEST
Target: Measure time from [Client Send] -> [IDS Process] -> [ML API Predict] -> [Client Receive]
Added: Visualization (Latency Chart by Stages)
"""
import requests
import time
import pandas as pd
import numpy as np
import concurrent.futures
import json
import os
import sys
import matplotlib.pyplot as plt  # Thư viện vẽ biểu đồ

# --- CẤU HÌNH ---
IDS_URL = "http://ids.qmuit.id.vn"
CSV_PATH = "test1.csv" # Đảm bảo file này nằm cùng thư mục

SAMPLE_SIZE = 1000       # Tổng số flow muốn test
CONCURRENT_USERS = 10   # Số user giả lập
BATCH_SIZE = 100         # Kích thước mỗi giai đoạn để vẽ biểu đồ (100 flows/nhóm)

# --- XỬ LÝ DỮ LIỆU ---
class NpEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.integer): return int(obj)
        if isinstance(obj, np.floating): return float(obj)
        if isinstance(obj, np.ndarray): return obj.tolist()
        return super(NpEncoder, self).default(obj)

def send_request(row_data, idx):
    """Gửi 1 request và đo latency"""
    payload = json.loads(json.dumps(row_data, cls=NpEncoder))
    
    headers = {
        "User-Agent": "LoadTest/1.0",
        "Content-Type": "application/json",
        "Connection": "close" 
    }

    start_time = time.time()
    result = {
        "idx": idx,
        "success": False,
        "latency": 0,
        "code": 0,
        "prediction": "unknown"
    }

    try:
        response = requests.post(
            f"{IDS_URL}/ingest_flow",
            json=payload,
            headers=headers,
            timeout=30
        )
        
        latency_ms = (time.time() - start_time) * 1000
        result["latency"] = latency_ms
        result["code"] = response.status_code

        if response.status_code == 200:
            data = response.json()
            result["success"] = True
            result["prediction"] = data.get("binary_prediction", "unknown")
        
    except Exception as e:
        result["latency"] = (time.time() - start_time) * 1000
        result["prediction"] = f"Error: {str(e)}"

    return result

def run_test():
    print("=" * 80)
    print(f"🚀 SCENARIO 1: INFERENCE LATENCY TEST (n={SAMPLE_SIZE})")
    print(f"ℹ️  Mode: Concurrent ({CONCURRENT_USERS} workers) | Chart Batch: {BATCH_SIZE} flows")
    print("=" * 80)

    if not os.path.exists(CSV_PATH):
        print(f"❌ Error: Không tìm thấy file tại {CSV_PATH}")
        return

    df = pd.read_csv(CSV_PATH).head(SAMPLE_SIZE)
    rows = [row.to_dict() for _, row in df.iterrows()]
    
    results = []
    print(f"\n[1] Sending {SAMPLE_SIZE} flows to {IDS_URL}...")
    
    start_test_time = time.time()
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=CONCURRENT_USERS) as executor:
        future_to_idx = {executor.submit(send_request, rows[i], i): i for i in range(len(rows))}
        
        completed = 0
        for future in concurrent.futures.as_completed(future_to_idx):
            res = future.result()
            results.append(res)
            completed += 1
            
            # In log mỗi khi hoàn thành 1 batch (theo BATCH_SIZE)
            if completed % BATCH_SIZE == 0 or completed == SAMPLE_SIZE:
                icon = "✅" if res["success"] else "❌"
                print(f"{icon} [{completed}/{SAMPLE_SIZE}] Latency: {res['latency']:.2f}ms | Pred: {res['prediction']}")

    total_duration = time.time() - start_test_time
    
    # --- PHÂN TÍCH & BÁO CÁO ---
    print("\n" + "=" * 80)
    print("📊 KẾT QUẢ PHÂN TÍCH")
    print("=" * 80)

    df_res = pd.DataFrame(results)
    
    # Chỉ lấy các request thành công để tính toán
    df_success = df_res[df_res['success'] == True].copy()
    
    if not df_success.empty:
        latencies = df_success['latency'].values
        
        print(f"Total Requests:      {len(results)}")
        print(f"Success:             {len(df_success)}")
        print(f"Throughput:          {len(results)/total_duration:.2f} req/s")
        print("-" * 40)
        print(f"Mean Latency:        {latencies.mean():.2f} ms")
        print(f"Median (P50):        {np.percentile(latencies, 50):.2f} ms")
        print(f"P95 Latency:         {np.percentile(latencies, 95):.2f} ms")
        print(f"P99 Latency:         {np.percentile(latencies, 99):.2f} ms")
        print(f"Max Latency:         {latencies.max():.2f} ms")
        print("-" * 40)
        
        # Lưu CSV chi tiết
        df_res.to_csv("scenario1_results.csv", index=False)
        print(f"📁 Raw Data saved to 'scenario1_results.csv'")

        # --- VẼ BIỂU ĐỒ (NEW FEATURE) ---
        print("\n[2] Generating Latency Chart...")
        try:
            # 1. Sắp xếp lại theo thứ tự index (để đúng trình tự gửi/nhận)
            df_success = df_success.sort_values('idx')
            
            # 2. Tạo cột nhóm (Batch)
            # Ví dụ: idx 0-19 -> Batch 1, idx 20-39 -> Batch 2
            df_success['batch_group'] = (df_success['idx'] // BATCH_SIZE) + 1
            
            # 3. Tính trung bình latency cho từng nhóm
            batch_stats = df_success.groupby('batch_group')['latency'].mean()
            
            # 4. Vẽ biểu đồ
            plt.figure(figsize=(10, 6))
            
            # Vẽ đường trung bình (Line chart)
            plt.plot(batch_stats.index, batch_stats.values, 
                     marker='o', linestyle='-', linewidth=2, color='#007acc', label='Avg Latency per Batch')
            
            # Trang trí biểu đồ
            plt.title(f'End-to-End Latency Trend (Batch Size = {BATCH_SIZE})', fontsize=14)
            plt.xlabel('Giai đoạn (Stage of Flows)', fontsize=12)
            plt.ylabel('Latency (ms)', fontsize=12)
            plt.grid(True, linestyle='--', alpha=0.7)
            
            # Gán nhãn trục X cho dễ hiểu (ví dụ: "1-20", "21-40")
            labels = [f"{i*BATCH_SIZE+1}-{(i+1)*BATCH_SIZE}" for i in range(len(batch_stats))]
            plt.xticks(batch_stats.index, labels)
            
            # Hiển thị giá trị trên từng điểm
            for x, y in zip(batch_stats.index, batch_stats.values):
                plt.annotate(f'{y:.0f}ms', 
                             (x, y), 
                             textcoords="offset points", 
                             xytext=(0,10), 
                             ha='center',
                             fontweight='bold')
            
            plt.legend()
            
            # Lưu file ảnh
            chart_filename = 'latency_chart.png'
            plt.savefig(chart_filename)
            print(f"✅ Chart saved to '{chart_filename}' (Mở file này để xem biểu đồ)")
            
        except Exception as e:
            print(f"❌ Could not generate chart: {e}")
            import traceback
            traceback.print_exc()

    else:
        print("❌ Không có request nào thành công. Kiểm tra lại Server/Network.")

if __name__ == "__main__":
    run_test()