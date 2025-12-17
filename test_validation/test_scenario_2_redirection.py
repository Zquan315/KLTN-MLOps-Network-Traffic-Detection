#!/usr/bin/env python3
"""
SCENARIO 2: REDIRECTION LATENCY TEST (SERVER-SIDE METRICS)
Target: Measure time from [IDS Detect] -> [Send to Honeypot] -> [Success]
Method: Trigger attacks -> Fetch internal metrics from metrics_collector.py
"""
import requests
import time
import pandas as pd
import numpy as np
import concurrent.futures
import json
import os
import sys

# --- CẤU HÌNH ---
IDS_URL = "http://ids.qmuit.id.vn"
CSV_PATH = "test1.csv"  # File CSV chứa dữ liệu tấn công

SAMPLE_SIZE = 1000      # Số lượng flows để test
CONCURRENT_USERS = 10   # Số luồng gửi trigger

# --- HELPER ---
class NpEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.integer): return int(obj)
        if isinstance(obj, np.floating): return float(obj)
        if isinstance(obj, np.ndarray): return obj.tolist()
        return super(NpEncoder, self).default(obj)

def send_trigger(row_data):
    """Gửi request để kích hoạt logic redirect trong IDS"""
    payload = json.loads(json.dumps(row_data, cls=NpEncoder))
    try:
        # Chỉ gửi để kích hoạt, không quan tâm response latency ở đây
        requests.post(f"{IDS_URL}/ingest_flow", json=payload, headers={"Connection": "close"}, timeout=5)
    except:
        pass

def run_test():
    print("=" * 80)
    print(f"🚀 SCENARIO 2: INTERNAL REDIRECTION LATENCY (n={SAMPLE_SIZE})")
    print("=" * 80)

    # 1. Lấy trạng thái cũ (để so sánh)
    try:
        initial_stats = requests.get(f"{IDS_URL}/redirection/stats", timeout=5).json()
        initial_count = initial_stats.get("summary", {}).get("total_attempts", 0)
        print(f"[1] Baseline: Hệ thống đang có {initial_count} redirections cũ.")
    except:
        initial_count = 0
        print("[1] Baseline: Không kết nối được API stats (Hệ thống sạch?)")

    # 2. Gửi Traffic Tấn công
    print(f"\n[2] Triggering {SAMPLE_SIZE} attacks to IDS...")
    if not os.path.exists(CSV_PATH):
        print("❌ CSV File not found!"); return

    df = pd.read_csv(CSV_PATH).head(SAMPLE_SIZE)
    rows = [row.to_dict() for _, row in df.iterrows()]
    
    start_time = time.time()
    with concurrent.futures.ThreadPoolExecutor(max_workers=CONCURRENT_USERS) as executor:
        list(executor.map(send_trigger, rows))
    
    duration = time.time() - start_time
    print(f"    -> Trigger xong trong {duration:.2f}s.")

    # 3. Chờ xử lý (Redirection là synchronous trong application.py, nhưng chờ xíu cho chắc)
    print("\n[3] Waiting 5s for metrics aggregation...")
    time.sleep(5)

    # 4. Lấy Metrics kết quả
    print("[4] Fetching Server-Side Metrics...")
    try:
        resp = requests.get(f"{IDS_URL}/redirection/stats", timeout=10)
        data = resp.json()
        
        summary = data.get("summary", {})
        latency = data.get("latency_ms", {})
        stealth = data.get("stealth_analysis", {})
        baseline = data.get("baseline_comparison", {})
        
        final_count = summary.get("total_attempts", 0)
        new_redirections = final_count - initial_count

        print("\n" + "=" * 80)
        print("📊 KẾT QUẢ ĐO LƯỜNG NỘI BỘ (Internal Redirection Performance)")
        print("=" * 80)
        
        print(f"Total New Redirections: {new_redirections} / {SAMPLE_SIZE}")
        print(f"Success Rate:           {summary.get('success_rate_percent', 0):.1f}%")
        print("-" * 40)
        
        print("⏱️  LATENCY STATISTICS (IDS -> Honeypot):")
        print(f"   Mean:       {latency.get('mean')} ms  (Paper Baseline: 2.3 ms)")
        print(f"   Median:     {latency.get('median')} ms")
        print(f"   P95:        {latency.get('p95')} ms   (Target: < 10 ms)")
        print(f"   P99:        {latency.get('p99')} ms")
        print(f"   Max:        {latency.get('max')} ms")
        print("-" * 40)
        
        print("🕵️  STEALTH ANALYSIS (Khả năng tàng hình):")
        print(f"   Requests < 10ms:    {stealth.get('below_10ms_count')} ({stealth.get('below_10ms_percent')}%)")
        
        is_stealthy = stealth.get("stealth_requirement_met")
        status = "✅ ĐẠT (Stealthy)" if is_stealthy else "❌ KHÔNG ĐẠT (Detectable)"
        print(f"   Status:             {status}")
        
        print("-" * 40)
        print(f"ℹ️  So sánh với Paper gốc:")
        print(f"   Chậm hơn Mean:      +{baseline.get('mean_delta_ms'):.2f} ms")
        
    except Exception as e:
        print(f"❌ Error fetching stats: {e}")

if __name__ == "__main__":
    run_test()