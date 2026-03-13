#!/bin/bash
# ============================================================
# INCIDENT 2: Memory Leak / Runaway Process
# Target: VM3 (192.168.200.10) - Target Server
# Run this script ON VM3
# Requires: stress-ng (install: sudo dnf install -y stress-ng)
# ============================================================

echo "======================================"
echo "  INCIDENT 2: MEMORY LEAK SIMULATION"
echo "======================================"
echo ""

# Install stress-ng if not present
if ! command -v stress-ng &>/dev/null; then
    echo "[SETUP] Installing stress-ng..."
    sudo dnf install -y stress-ng
fi

echo "[STEP 1] Check memory BEFORE incident"
free -h
echo ""
echo "Top memory consumers:"
ps aux --sort=-%mem | head -8
echo ""

echo "[STEP 2] Triggering memory leak with stress-ng..."
echo "  This will consume RAM until >85% alert fires"
echo "  Runs for 300 seconds (5 minutes) then auto-stops"
echo ""

# Allocate memory workers - adjust --vm-bytes based on your VM's RAM
# For 1GB RAM VM: 800m will push above 85%
# For 2GB RAM VM: 1700m will push above 85%
stress-ng --vm 2 --vm-bytes 80% --vm-method all --timeout 300s &
STRESS_PID=$!
echo "  stress-ng started with PID: $STRESS_PID"
echo ""

echo "[MONITORING - watch in another terminal]:"
echo "  watch -n 2 'free -h && echo && ps aux --sort=-%mem | head -5'"
echo ""
echo "[GRAFANA] Watch: 'Memory Usage %' panel"
echo "  Alert fires when RAM usage > 85%"
echo ""

echo "[INVESTIGATION COMMANDS - run after alert fires]:"
cat << 'EOF'

  # 1. Check overall memory state
  free -h

  # 2. Find top memory-consuming processes
  ps aux --sort=-%mem | head -15

  # 3. See real-time process memory
  top -o %MEM

  # 4. Check which process is growing
  watch -n 2 'ps aux --sort=-%mem | head -5'

  # 5. Deep inspect a suspicious PID (replace 1234 with actual PID)
  cat /proc/1234/status | grep -E 'VmRSS|VmPeak|VmSize'
  ls -la /proc/1234/exe

EOF

echo "[FIX COMMANDS]:"
cat << 'EOF'

  # Option 1: Kill the stress-ng process
  kill <PID>              # Graceful
  kill -9 <PID>           # Force kill if graceful fails

  # Option 2: Kill all stress-ng instances
  pkill stress-ng

  # Option 3: Kill by name if unknown process
  ps aux | grep <suspicious_name>
  kill -9 <PID>

  # Verify memory recovered
  free -h

EOF

# Wait for stress-ng to finish or manual kill
wait $STRESS_PID 2>/dev/null
echo ""
echo "[INFO] stress-ng process has ended."
echo "  Run 'free -h' to confirm memory is released."
