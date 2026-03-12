#!/bin/bash
# ============================================================
# INCIDENT 1: Disk Fill Simulation
# Target: VM3 (192.168.200.10) - Target Server
# Run this script ON VM3
# ============================================================

echo ""
echo "[STEP 1] Check current disk usage BEFORE incident"
df -h /
echo ""
echo "[STEP 2] Triggering disk fill with dummy files..."
echo "  Creating large files in /tmp/incident-test/"
mkdir -p /tmp/incident-test

# Fill disk to trigger >85% alert
# Adjust count based on your free space
for i in {1..5}; do
    dd if=/dev/zero of=/tmp/incident-test/bigfile_$i bs=1M count=500 status=progress 2>&1
    echo "  Created bigfile_$i (500MB)"
    echo "  Current disk usage:"
    df -h /
    echo ""
    sleep 10  # Wait between writes so Grafana can detect
done

echo ""
echo "[STEP 3] Disk fill triggered. Now:"
echo "  - Watch Grafana panel: 'Disk Usage %'"
echo "  - Alert should fire when usage crosses 85%"
echo "  - Check VM2 Grafana → Alerting → Alert Rules"
echo ""
echo "[COMMANDS - run after Grafana alerts]:"
echo "  df -h                          # See all mount points"
echo "  du -sh /tmp/incident-test/     # Find large directories"
echo "  du -h / --max-depth=2 2>/dev/null | sort -rh | head -20"
echo "  ls -lh /tmp/incident-test/     # Confirm the culprit files"
echo "  lsof | grep deleted            # Find files held open by processes"
echo ""
echo "[FIX COMMANDS]:"
echo "  rm -rf /tmp/incident-test/     # Remove dummy files"
echo "  df -h /                        # Verify disk recovered"
