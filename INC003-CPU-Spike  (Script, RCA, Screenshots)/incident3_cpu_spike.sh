#!/bin/bash
# ============================================================
# INCIDENT 3: CPU Spike
# Target: VM3 (192.168.200.10) - Target Server
# Run this script ON VM3
# Requires: stress-ng (sudo dnf install -y stress-ng)
# ============================================================

echo "======================================"
echo "  INCIDENT 3: CPU SPIKE SIMULATION"
echo "======================================"
echo ""

if ! command -v stress-ng &>/dev/null; then
    echo "[SETUP] Installing stress-ng..."
    sudo dnf install -y stress-ng
fi

# Count available CPUs
CPU_COUNT=$(nproc)
echo "[INFO] Detected $CPU_COUNT CPU(s) on this VM"

echo "[STEP 1] Check CPU BEFORE incident"
echo "Current CPU usage:"
top -bn1 | grep "Cpu(s)"
uptime
echo ""
echo "Top CPU consumers:"
ps aux --sort=-%cpu | head -8
echo ""

echo "[STEP 2] Triggering CPU spike..."
echo "  Running stress-ng with $CPU_COUNT CPU workers for 180 seconds"
echo "  This will spike CPU to ~100% and trigger Grafana alert (>80%)"
echo ""

stress-ng --cpu $CPU_COUNT --timeout 180s &
STRESS_PID=$!
echo "  stress-ng PID: $STRESS_PID"
echo ""

echo "[MONITORING - watch in another terminal]:"
echo "  watch -n 2 'top -bn1 | head -15'"
echo "  watch -n 2 'mpstat 1 1'"
echo ""
echo "[GRAFANA] Watch: 'CPU Usage %' panel"
echo "  Alert fires when CPU > 80%"
echo ""

echo "[INVESTIGATION COMMANDS - after Grafana fires]:"
cat << 'EOF'

  # 1. Overall CPU state
  top -bn1 | head -20
  uptime   # Load averages (1, 5, 15 min)

  # 2. Find CPU-hungry processes
  ps aux --sort=-%cpu | head -10

  # 3. Per-core CPU usage
  mpstat -P ALL 1 3

  # 4. Real-time process view sorted by CPU
  top     # then press 'P' to sort by CPU

  # 5. Check if it's a known cron job
  cat /etc/crontab
  ls /etc/cron.d/

  # 6. Check system call activity on a PID
  strace -p <PID> -c   # Summary of syscalls (Ctrl+C to stop)

EOF

echo "[FIX COMMANDS]:"
cat << 'EOF'

  # Kill the runaway process
  kill <PID>
  kill -9 <PID>     # Force if needed

  # Kill all stress-ng instances
  pkill stress-ng

  # Verify CPU returned to normal
  top -bn1 | grep "Cpu(s)"
  uptime

EOF

wait $STRESS_PID 2>/dev/null
echo ""
echo "[INFO] CPU stress has ended. Verify recovery with: uptime"
