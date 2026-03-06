# Runbook — High CPU Alert Investigation (Azure Monitor)

## Purpose
This runbook describes how to investigate and respond to the **High CPU** Azure Monitor alert for the lab VM **vm-web-dev**.

- **Alert name:** `alert-high-cpu-dev`
- **Signal type:** Metric alert (Percentage CPU)
- **Severity:** 2 (Warning)
- **Threshold:** Average CPU > 80% over 5 minutes
- **Target resource:** `vm-web-dev`

---

## Triage Checklist (1–2 minutes)

1. **Confirm alert fired**
   - Azure Portal → Monitor → Alerts → open the alert instance.
   - Validate: VM = `vm-web-dev`, condition = Fired, CPU threshold exceeded.

2. **Check if this is expected**
   - Did you (or CI) run a stress test or heavy workload recently?
   - Is this a known maintenance window or scheduled job?
   - If yes, document as expected and skip to Step 5 (Resolve).

3. **Confirm VM is reachable**
   - SSH to the VM or validate service health.
   - Confirm the nginx page still loads at `http://<VM_PUBLIC_IP>`.

---

## Investigation Steps

### Step 1 — Confirm CPU Spike in Log Analytics (KQL)

Open Azure Portal → Log Analytics workspace (`law-infra-lab-dev`) → Logs.

Run this query against the Perf table to see the CPU trend over the last 30 minutes:

```kql
Perf
| where TimeGenerated > ago(30m)
| where Computer == "vm-web-dev"
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| where InstanceName == "_Total"
| summarize AvgCPU = avg(CounterValue), MaxCPU = max(CounterValue) by bin(TimeGenerated, 1m)
| order by TimeGenerated asc
```

**What to look for:**
- A sudden spike to 90–100% suggests a runaway process or unexpected load.
- A gradual climb over hours suggests a capacity issue or memory leak causing CPU pressure.
- A brief spike that already resolved may indicate a scheduled task (e.g., cron job, package update).

### Step 2 — Check for Correlated Syslog Events

Still in Log Analytics, check if any system-level errors occurred at the same time as the CPU spike:

```kql
Syslog
| where TimeGenerated > ago(30m)
| where Computer == "vm-web-dev"
| where SeverityLevel in ("err", "crit", "alert", "emerg")
| project TimeGenerated, Facility, SeverityLevel, SyslogMessage
| order by TimeGenerated desc
```

**What to look for:**
- OOM (out of memory) killer messages from the `kern` facility — indicates the system ran out of memory and started killing processes, which can cause CPU churn.
- Service crash/restart loops from `daemon` — a crashing service restarting repeatedly can consume CPU.
- Auth failures from `auth` or `authpriv` — a brute-force SSH attack can cause measurable CPU load on small VMs.

### Step 3 — Identify High-CPU Processes on the VM

SSH into the VM:

```bash
ssh -i ~/.ssh/azure-lab-key azureadmin@<VM_PUBLIC_IP>
```

Run the following commands:

```bash
# Real-time process view sorted by CPU
top -bn1 | head -20

# Snapshot of top CPU consumers
ps aux --sort=-%cpu | head -15

# Check if stress-ng is running (from a previous test)
pgrep -a stress
```

**What to look for:**
- `stress-ng` still running from a previous test — kill it.
- A specific application or service consuming high CPU (e.g., nginx, a cron job, a package update).
- System processes like `apt` or `dpkg` running — likely an unattended upgrade from cloud-init.

### Step 4 — Remediate

Based on what you found in Step 3:

| Root Cause | Action |
|---|---|
| `stress-ng` left running from a test | `sudo killall stress-ng` |
| Runaway process (known PID) | `sudo kill -9 <PID>` |
| Unattended package upgrade | Wait for it to complete (typically 5–10 min) |
| Brute-force SSH attempts | Verify NSG restricts SSH to `allowed_ssh_ip` only; check with `sudo journalctl -u sshd --since "30 min ago"` |
| Legitimate sustained load | Consider scaling the VM size (e.g., `Standard_D2s_v3` → `Standard_D4s_v3`) by updating `compute.tf` and running the CI/CD pipeline |
| Recurring cron job | Review with `crontab -l` and `sudo crontab -l`; reschedule or optimize the job |

After remediation, confirm CPU has dropped:

```bash
top -bn1 | grep "Cpu(s)"
```

You should see idle (`id`) percentage return to 90%+ on a healthy system.

### Step 5 — Verify Alert Auto-Resolves

Once CPU returns below the 80% threshold for the evaluation window (5 minutes), the alert will auto-resolve in Azure Monitor.

1. Azure Portal → Monitor → Alerts — confirm the alert state changes from **Fired** to **Resolved**.
2. Check your email for the resolution notification from the action group.

If the alert does not auto-resolve after 10 minutes despite CPU being normal, check:
- Is the VM heartbeat still reporting? (Portal → VM → Overview → check status)
- Is the alert rule still enabled? (Monitor → Alerts → Alert rules)

### Step 6 — Document and Close

Record the following for future reference:

- **When:** Date/time the alert fired and resolved.
- **What:** Root cause identified (e.g., "stress-ng left running from alert validation test").
- **Action taken:** Specific remediation (e.g., "killed stress-ng process PID 12345").
- **Follow-up needed:** Any changes to prevent recurrence (e.g., "add timeout flag to future stress tests," "consider adjusting alert threshold," "scale VM if load is legitimate").

---

## Escalation

This is a lab environment with a single operator. In a production setting, escalation would follow:

1. **Sev 2 (this alert):** On-call engineer investigates within 30 minutes.
2. **If unresolved after 1 hour:** Escalate to team lead or senior engineer.
3. **If affecting production services:** Engage incident management process.

---

## Related Resources

- **KQL queries:** `kql/top-cpu.kql`, `kql/syslog-errors.kql`
- **Alert rule definition:** `infra/alerts.tf` → `azurerm_monitor_metric_alert.high_cpu`
- **VM configuration:** `infra/compute.tf`
- **Architecture diagram:** `docs/diagrams/architecture.svg`