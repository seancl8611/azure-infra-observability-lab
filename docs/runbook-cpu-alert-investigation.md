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
   - Did you (or CI) run a stress test / heavy workload recently?
   - If yes, document as expected and continue to verification.

3. **Confirm VM is reachable**
   - SSH to the VM (or validate service health).
   - Confirm nginx page still loads (if web service is part of the lab proof).

---

## Investigation Steps

### 1) Confirm CPU spike in Log Analytics (KQL)
Azure Portal → Log Analytics workspace (`law-infra-lab-dev`) → Logs.

Run this query (Perf table):

```kql
Perf
| where TimeGenerated > ago(30m)
| where Computer == "vm-web-dev"
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| summarize AvgCPU = avg(CounterValue), MaxCPU = max(CounterValue) by bin(TimeGenerated, 1m)
| order by TimeGenerated asc