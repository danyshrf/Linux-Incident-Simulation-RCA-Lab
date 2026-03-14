# Root Cause Analysis: INC-003 (CPU Spike)

**Lab Project:** KVM Monitoring Stack  
**Affected System:** VM3 — Target Server (`192.168.200.10`)  
**Severity:** HIGH  

---

## 1. Incident Summary
On the simulated environment, the CPU utilization on VM3 sustained a spike to ~100%, triggering a critical monitoring alert.

* **Incident ID:** INC-003
* **Detection Method:** Grafana Alert: "High CPU Alert" (>80% threshold).
* **Reported By:** Grafana Alerting → Email Notification.

---

## 2. Impact
* **System Health:** The system became sluggish, and all other processes on VM3 were starved for CPU cycles. SSH sessions to VM3 experienced significant latency during the incident.
* **Monitoring:** Node Exporter continued reporting metrics successfully, as its priority was preserved by the kernel.

---

## 3. Timeline
| Time | Event |
| :--- | :--- |
| **T+90:10** | `stress-ng` launched — CPU workers started. |
| **T+90:15** | CPU usage jumped to ~100% — Grafana panel showed immediate spike. |
| **T+90:25** | Grafana "High CPU Alert" entered PENDING state. |
| **T+90:27** | **Alert FIRING** — notification dispatched. |
| **T+:9.28** | Investigation — `ps aux` / `top` confirmed `stress-ng` as culprit. |
| **T+9:35** | **Remediation** — `pkill stress-ng` executed. |
| **T+9.37** | CPU returned to baseline (<5%) — alert resolved. |

---

## 4. Technical Root Cause
The incident was deliberately caused by a CPU stress simulation (`stress-ng`) run with one worker per CPU core, effectively consuming all available CPU cycles.

In a real-world production environment, equivalent scenarios include:
* A runaway application loop with no sleep/yield (an infinite tight loop in the code).
* A cryptocurrency miner deployed by an attacker on a compromised server.
* Compiling large software or ML model training monopolizing the CPU.
* A database performing a full table scan on a multi-million row table.
* A poorly written cron job triggered at peak hours.

---

## 5. Investigation & Remediation

### Diagnostic Path
The following commands were used for immediate assessment and process identification:
* **Immediate Assessment:** `uptime` to check load averages (1m/5m/15m), and `top -bn1 | head -20` for a snapshot of top processes.
* **Identifying the Process:** `ps aux --sort=-%cpu | head -10` to view top CPU consumers, alongside interactive `top`.
* **Per-Core Analysis:** `mpstat -P ALL 1 3` to view per-core utilization, and `iostat -x 1 3` for a combined CPU and I/O view.
* **Process Ancestry:** `pstree -p <PID>` to see how the process was spawned, and `cat /proc/<PID>/cmdline | tr "\0" " "` for the full command line.

### Recovery Action
| Step | Action | Command |
| :--- | :--- | :--- |
| 1 | Confirm load average abnormally high | `uptime` |
| 2 | Identify top CPU process and PID | `ps aux --sort=-%cpu | head -5` |
| 3 | Immediate Remediation | `pkill stress-ng` |
| 4 | Verify load averages dropping | `uptime` (wait 1-2 minutes) |
| 5 | Confirm Grafana alert resolved | Grafana → Alerting → Alert Rules |

---

## 6. Monitoring & Alert Behavior
The alert was triggered by the following PromQL expression, which fired within 15 seconds of the CPU reaching the threshold: `100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80`.

* The "CPU Usage %" panel showed an instant vertical spike from baseline to ~100%.
* Recovery was visible in Grafana within one scrape interval (15s) of the process being killed.

---

## 7. Preventive Measures
To mitigate CPU monopolization in the future, the following measures are recommended:
* **Resource Limits:** Implement CPU usage hard limits per process using cgroups or `systemd CPUQuota=`. Use resource limits in `/etc/security/limits.conf` for system-wide enforcement.
* **Tiered Alerting:** Set an alert at 70% for early warning before the 80% critical threshold is reached.
* **Job Scheduling:** Schedule cron jobs using `nice`/`ionice` to prevent them from monopolizing the CPU.
* **Security Monitoring:** Enable `auditd` to log the execution of new processes for security auditing.
