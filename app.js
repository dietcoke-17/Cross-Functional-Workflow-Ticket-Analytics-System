/**
 * app.js
 * Cross-Functional Workflow & Ticket Analytics System Dashboard
 * Interactive charts, live Guesstimate ROI calculator, and SQL query viewer.
 */

// Default embedded analytics dataset (guarantees local file:// execution without CORS failure)
const DEFAULT_METRICS = {
  "kpis": {
    "total_tickets": 10500,
    "baseline_avg_hours": 28.32,
    "optimized_avg_hours": 21.12,
    "cycle_time_reduction_pct": 25.4,
    "baseline_breach_rate": 28.6,
    "optimized_breach_rate": 20.5,
    "breach_rate_drop_pts": 8.1,
    "baseline_clean_rate": 68.8,
    "optimized_clean_rate": 87.7,
    "clean_rate_lift_pts": 18.9,
    "bottleneck_hours": 30246.5,
    "bottleneck_cost_usd": 1058627.15,
    "automation_savings_usd": 793970.36,
    "net_benefit_usd": 728970.36
  },
  "monthly_trend": [
    { "month": "2026-01", "workflow_phase": "Baseline (Q1 2026)", "volume": 1769, "avg_hours": 28.4, "breach_rate": 29.6 },
    { "month": "2026-02", "workflow_phase": "Baseline (Q1 2026)", "volume": 1680, "avg_hours": 28.4, "breach_rate": 27.7 },
    { "month": "2026-03", "workflow_phase": "Baseline (Q1 2026)", "volume": 1784, "avg_hours": 28.2, "breach_rate": 28.4 },
    { "month": "2026-04", "workflow_phase": "Optimized (Q2 2026)", "volume": 1683, "avg_hours": 21.2, "breach_rate": 20.5 },
    { "month": "2026-05", "workflow_phase": "Optimized (Q2 2026)", "volume": 1840, "avg_hours": 20.2, "breach_rate": 18.6 },
    { "month": "2026-06", "workflow_phase": "Optimized (Q2 2026)", "volume": 1744, "avg_hours": 22.0, "breach_rate": 22.6 }
  ],
  "departments": [
    { "department": "Legal & Compliance", "total_tickets": 2442, "avg_hours": 33.4, "avg_queue_wait": 5.8, "breach_rate_pct": 36.9, "financial_labor_waste_usd": 286200 },
    { "department": "Finance & Accounting", "total_tickets": 2361, "avg_hours": 28.3, "avg_queue_wait": 5.6, "breach_rate_pct": 28.6, "financial_labor_waste_usd": 248900 },
    { "department": "Catalog & Operations", "total_tickets": 2528, "avg_hours": 22.4, "avg_queue_wait": 5.7, "breach_rate_pct": 20.4, "financial_labor_waste_usd": 221500 },
    { "department": "Technical Support", "total_tickets": 1626, "avg_hours": 17.4, "avg_queue_wait": 5.4, "breach_rate_pct": 16.5, "financial_labor_waste_usd": 154300 },
    { "department": "Central Vendor Operations", "total_tickets": 1543, "avg_hours": 17.0, "avg_queue_wait": 5.6, "breach_rate_pct": 14.1, "financial_labor_waste_usd": 147700 }
  ],
  "stages": [
    { "onboarding_stage": "1. Intake & Verification", "volume": 1227, "avg_queue_hours": 5.6, "avg_handling_hours": 11.3, "avg_total_hours": 16.9, "breach_rate_pct": 14.8 },
    { "onboarding_stage": "2. Legal & KYC", "volume": 2442, "avg_queue_hours": 5.8, "avg_handling_hours": 27.6, "avg_total_hours": 33.4, "breach_rate_pct": 36.9 },
    { "onboarding_stage": "3. Banking & Tax", "volume": 2361, "avg_queue_hours": 5.6, "avg_handling_hours": 22.7, "avg_total_hours": 28.3, "breach_rate_pct": 28.6 },
    { "onboarding_stage": "4. Catalog Ingestion", "volume": 3557, "avg_queue_hours": 5.7, "avg_handling_hours": 15.4, "avg_total_hours": 21.1, "breach_rate_pct": 19.6 },
    { "onboarding_stage": "5. Final Activation", "volume": 913, "avg_queue_hours": 5.5, "avg_handling_hours": 11.4, "avg_total_hours": 16.9, "breach_rate_pct": 13.5 }
  ],
  "hourly_distribution": [
    { "hour": 8, "volume_pct": 3.7, "lambda": 3.27, "baseline_staff": 2.92, "proposed_staff": 2.50, "baseline_q": 1.05, "proposed_q": 3.50 },
    { "hour": 9, "volume_pct": 4.9, "lambda": 4.36, "baseline_staff": 2.92, "proposed_staff": 2.50, "baseline_q": 1.32, "proposed_q": 4.36 },
    { "hour": 10, "volume_pct": 14.2, "lambda": 7.62, "baseline_staff": 2.92, "proposed_staff": 5.25, "baseline_q": 4.85, "proposed_q": 4.63 },
    { "hour": 11, "volume_pct": 15.3, "lambda": 8.17, "baseline_staff": 2.92, "proposed_staff": 5.25, "baseline_q": 8.93, "proposed_q": 5.45 },
    { "hour": 12, "volume_pct": 13.1, "lambda": 7.08, "baseline_staff": 2.92, "proposed_staff": 5.25, "baseline_q": 11.93, "proposed_q": 5.18 },
    { "hour": 13, "volume_pct": 11.8, "lambda": 6.54, "baseline_staff": 2.92, "proposed_staff": 5.25, "baseline_q": 14.37, "proposed_q": 4.37 },
    { "hour": 14, "volume_pct": 10.5, "lambda": 5.99, "baseline_staff": 2.92, "proposed_staff": 5.25, "baseline_q": 16.28, "proposed_q": 3.01 },
    { "hour": 15, "volume_pct": 5.6, "lambda": 3.27, "baseline_staff": 2.92, "proposed_staff": 2.50, "baseline_q": 15.45, "proposed_q": 2.78 },
    { "hour": 16, "volume_pct": 3.5, "lambda": 2.18, "baseline_staff": 2.92, "proposed_staff": 2.50, "baseline_q": 13.55, "proposed_q": 1.45 },
    { "hour": 17, "volume_pct": 1.9, "lambda": 1.09, "baseline_staff": 2.92, "proposed_staff": 1.40, "baseline_q": 10.55, "proposed_q": 0.58 },
    { "hour": 18, "volume_pct": 1.1, "lambda": 0.54, "baseline_staff": 2.92, "proposed_staff": 1.40, "baseline_q": 7.00, "proposed_q": 0.00 }
  ],
  "stakeholder_clearance": [
    { "department": "Legal & Compliance", "blockers": "KYC Document Blurry Scans & Redline Exceptions", "baseline": 59.0, "optimized": 85.2, "lift": 26.2 },
    { "department": "Finance & Accounting", "blockers": "W-9/TIN Mismatch & Micro-deposit Timeouts", "baseline": 67.6, "optimized": 87.4, "lift": 19.8 },
    { "department": "Catalog & Operations", "blockers": "SKU Attribute Schema Errors & GTIN Conflicts", "baseline": 74.8, "optimized": 91.2, "lift": 16.4 }
  ],
  "top_issues": [
    { "issue": "KYC Document Defect", "dept": "Legal & Compliance", "cost": 162400 },
    { "issue": "Tax Form Discrepancy (W-9)", "dept": "Finance & Accounting", "cost": 138600 },
    { "issue": "Bank Account Verification Failure", "dept": "Finance & Accounting", "cost": 131200 },
    { "issue": "SKU Catalog Format Error", "dept": "Catalog & Operations", "cost": 118400 },
    { "issue": "Contract Redlining Exception", "dept": "Legal & Compliance", "cost": 109800 }
  ]
};

const SQL_SNIPPETS = {
  "sla": `-- 02_sla_breach_analysis.sql
-- Monthly SLA Breach Trend Analysis using date-time functions and conditional aggregations
SELECT
    strftime('%Y-%m', created_at) AS report_month,
    workflow_phase,
    COUNT(*) AS total_ticket_volume,
    COUNT(CASE WHEN sla_breached = 0 THEN 1 END) AS tickets_within_sla,
    COUNT(CASE WHEN sla_breached = 1 THEN 1 END) AS tickets_breached_sla,
    ROUND(100.0 * COUNT(CASE WHEN sla_breached = 1 THEN 1 END) / COUNT(*), 2) AS sla_breach_rate_pct,
    ROUND(AVG(actual_resolution_hours), 2) AS avg_resolution_hours
FROM operational_tickets
GROUP BY strftime('%Y-%m', created_at), workflow_phase
ORDER BY report_month ASC;`,

  "bottleneck": `-- 03_bottleneck_isolation.sql
-- Isolates the stages contributing the greatest share of vendor onboarding latency
WITH StageMetrics AS (
    SELECT
        onboarding_stage,
        COUNT(*) AS stage_ticket_volume,
        ROUND(AVG(queue_wait_hours), 2) AS avg_queue_wait_hours,
        ROUND(AVG(actual_resolution_hours - queue_wait_hours), 2) AS avg_active_handling_hours,
        ROUND(AVG(actual_resolution_hours), 2) AS avg_total_cycle_hours,
        ROUND(100.0 * SUM(sla_breached) / COUNT(*), 2) AS stage_sla_breach_rate,
        SUM(actual_resolution_hours) AS sum_total_hours
    FROM operational_tickets
    GROUP BY onboarding_stage
)
SELECT
    onboarding_stage,
    stage_ticket_volume,
    avg_queue_wait_hours,
    avg_active_handling_hours,
    avg_total_cycle_hours,
    stage_sla_breach_rate,
    DENSE_RANK() OVER (ORDER BY avg_total_cycle_hours DESC) AS bottleneck_severity_rank
FROM StageMetrics
ORDER BY avg_total_cycle_hours DESC;`,

  "cte": `-- 04_department_resolution_cte.sql
-- Chained CTEs to segment ticket resolution times by issue type and department
WITH TicketLevelEnrichment AS (
    SELECT ticket_id, department, issue_type, queue_wait_hours,
           actual_resolution_hours, sla_target_hours, sla_breached
    FROM operational_tickets
),
DepartmentSummary AS (
    SELECT department,
           COUNT(*) AS total_dept_tickets,
           ROUND(AVG(actual_resolution_hours), 2) AS dept_avg_resolution_hours,
           ROUND(100.0 * SUM(sla_breached) / COUNT(*), 2) AS dept_sla_breach_rate_pct
    FROM TicketLevelEnrichment
    GROUP BY department
),
IssueTypeSegmentation AS (
    SELECT t.department, t.issue_type,
           COUNT(*) AS issue_ticket_volume,
           ROUND(AVG(t.actual_resolution_hours), 2) AS avg_resolution_hours,
           ROUND(100.0 * SUM(t.sla_breached) / COUNT(*), 2) AS issue_sla_breach_rate_pct
    FROM TicketLevelEnrichment t
    GROUP BY t.department, t.issue_type
)
SELECT department, issue_type, issue_ticket_volume,
       avg_resolution_hours, issue_sla_breach_rate_pct,
       DENSE_RANK() OVER (PARTITION BY department ORDER BY avg_resolution_hours DESC) AS dept_latency_rank
FROM IssueTypeSegmentation
ORDER BY department, dept_latency_rank;`,

  "peak": `-- 05_peak_hours_bandwidth.sql
-- Peak hour surge analysis identifying demand concentration between 10:00 and 15:00
SELECT
    created_hour,
    COUNT(*) AS tickets_created,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM operational_tickets), 2) AS pct_of_daily_volume,
    ROUND(AVG(queue_wait_hours), 2) AS avg_queue_wait_hours,
    SUM(sla_breached) AS sla_breaches_incurred,
    ROUND(100.0 * SUM(sla_breached) / COUNT(*), 2) AS hourly_breach_rate_pct
FROM operational_tickets
GROUP BY created_hour
ORDER BY created_hour ASC;`,

  "guesstimate": `-- 06_guesstimate_financial_cost.sql
-- Guesstimate Financial Model: Manual hours * associates involved * hourly rate
WITH EconomicParameters AS (
    SELECT 35.00 AS fully_loaded_hourly_rate_usd,
           0.75  AS automation_yield_potential
)
SELECT
    t.department,
    COUNT(*) AS total_ticket_volume,
    ROUND(SUM(t.manual_hours_spent * t.associates_involved), 1) AS total_person_hours_consumed,
    ROUND(SUM(t.manual_hours_spent * t.associates_involved) * p.fully_loaded_hourly_rate_usd, 2) AS financial_cost_of_bottlenecks_usd,
    ROUND(SUM(t.manual_hours_spent * t.associates_involved) * p.fully_loaded_hourly_rate_usd * p.automation_yield_potential, 2) AS projected_automation_savings_usd
FROM operational_tickets t
CROSS JOIN EconomicParameters p
WHERE t.sla_breached = 1 OR t.is_unresolved = 1
GROUP BY t.department;`,

  "resource": `-- 07_resource_allocation_model.sql
-- Proves 25% reduction in vendor onboarding cycle time via dynamic shift reallocation
SELECT
    'System-Wide Vendor Operations' AS scope,
    ROUND(AVG(CASE WHEN workflow_phase = 'Baseline (Q1 2026)' THEN actual_resolution_hours END), 2) AS baseline_avg_resolution_hours,
    ROUND(AVG(CASE WHEN workflow_phase = 'Optimized (Q2 2026)' THEN actual_resolution_hours END), 2) AS optimized_avg_resolution_hours,
    ROUND(
        ((AVG(CASE WHEN workflow_phase = 'Baseline (Q1 2026)' THEN actual_resolution_hours END) -
          AVG(CASE WHEN workflow_phase = 'Optimized (Q2 2026)' THEN actual_resolution_hours END)) /
         AVG(CASE WHEN workflow_phase = 'Baseline (Q1 2026)' THEN actual_resolution_hours END)) * 100.0,
        1
    ) AS verified_cycle_time_reduction_pct
FROM operational_tickets;`
};

// Application State
let analyticsData = DEFAULT_METRICS;
let charts = {};

document.addEventListener("DOMContentLoaded", () => {
  try { initTabs(); } catch (e) { console.error("initTabs error:", e); }
  try { initStakeholderTable(); } catch (e) { console.error("initStakeholderTable error:", e); }
  try { initCharts(); } catch (e) { console.error("initCharts error:", e); }
  try { initCalculator(); } catch (e) { console.error("initCalculator error:", e); }
  try { initSqlViewer(); } catch (e) { console.error("initSqlViewer error:", e); }
});

// Tab Switcher with Chart Resize Handler
function initTabs() {
  const tabs = document.querySelectorAll(".tab-btn");
  tabs.forEach(tab => {
    tab.addEventListener("click", () => {
      tabs.forEach(t => t.classList.remove("active"));
      document.querySelectorAll(".tab-pane").forEach(p => p.classList.remove("active"));
      tab.classList.add("active");
      const targetPane = document.getElementById(`pane-${tab.dataset.tab}`);
      if (targetPane) {
        targetPane.classList.add("active");
      }

      // Critical fix: force Chart.js instances to re-measure and adapt layout
      // when their container transitions from display: none to display: block
      setTimeout(() => {
        Object.values(charts).forEach(c => {
          if (c && typeof c.resize === "function") {
            try {
              c.resize();
            } catch (err) {
              console.warn("Chart resize warning:", err);
            }
          }
        });
        window.dispatchEvent(new Event("resize"));
      }, 60);
    });
  });
}

// Stakeholder Table
function initStakeholderTable() {
  const tbody = document.getElementById("stakeholderTableBody");
  if (!tbody) return;

  tbody.innerHTML = analyticsData.stakeholder_clearance.map(item => `
    <tr>
      <td><strong>${item.department}</strong></td>
      <td style="color: #9ca3af;">${item.blockers}</td>
      <td>${item.baseline.toFixed(1)}%</td>
      <td style="color: #10b981; font-weight: 600;">${item.optimized.toFixed(1)}%</td>
      <td><span class="badge-success">+${item.lift.toFixed(1)} pts</span></td>
      <td><span style="color: #10b981;">&#10003; Blocker Removed</span></td>
    </tr>
  `).join("");
}

// Chart Initializations
function initCharts() {
  if (typeof Chart === "undefined") {
    console.warn("Chart.js is not loaded. Displaying accessible data fallback.");
    document.querySelectorAll(".chart-container").forEach(el => {
      el.innerHTML = '<div style="display:flex;align-items:center;justify-content:center;height:100%;color:#9ca3af;font-size:13px;border:1px dashed #374151;border-radius:6px;padding:12px;text-align:center;">Interactive chart rendering requires Chart.js. If you are offline or using an ad-blocker, please allow cdn.jsdelivr.net or cdnjs.cloudflare.com.</div>';
    });
    return;
  }

  // Chart 1: Monthly Trend
  const ctxMonthly = document.getElementById("monthlyTrendChart");
  if (ctxMonthly) {
    charts.monthly = new Chart(ctxMonthly, {
      type: "bar",
      data: {
        labels: analyticsData.monthly_trend.map(m => m.month),
        datasets: [
          {
            type: "line",
            label: "SLA Breach Rate (%)",
            data: analyticsData.monthly_trend.map(m => m.breach_rate),
            borderColor: "#f43f5e",
            backgroundColor: "rgba(244, 63, 94, 0.1)",
            borderWidth: 3,
            yAxisID: "y1",
            tension: 0.3
          },
          {
            type: "bar",
            label: "Ticket Volume",
            data: analyticsData.monthly_trend.map(m => m.volume),
            backgroundColor: analyticsData.monthly_trend.map(m => m.workflow_phase.includes("Baseline") ? "rgba(59, 130, 246, 0.4)" : "rgba(16, 185, 129, 0.5)"),
            borderColor: analyticsData.monthly_trend.map(m => m.workflow_phase.includes("Baseline") ? "#3b82f6" : "#10b981"),
            borderWidth: 1,
            yAxisID: "y"
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { labels: { color: "#e5e7eb" } } },
        scales: {
          x: { ticks: { color: "#9ca3af" }, grid: { color: "rgba(55, 65, 81, 0.3)" } },
          y: { position: "left", ticks: { color: "#9ca3af" }, grid: { color: "rgba(55, 65, 81, 0.3)" }, title: { display: true, text: "Tickets", color: "#9ca3af" } },
          y1: { position: "right", ticks: { color: "#f43f5e" }, grid: { drawOnChartArea: false }, title: { display: true, text: "Breach %", color: "#f43f5e" } }
        }
      }
    });
  }

  // Chart 2: Department Breakdown
  const ctxDept = document.getElementById("departmentChart");
  if (ctxDept) {
    charts.dept = new Chart(ctxDept, {
      type: "bar",
      data: {
        labels: analyticsData.departments.map(d => d.department.split(" ")[0]),
        datasets: [
          {
            label: "Queue Wait Time (hrs)",
            data: analyticsData.departments.map(d => d.avg_queue_wait),
            backgroundColor: "#f59e0b"
          },
          {
            label: "Total Turnaround (hrs)",
            data: analyticsData.departments.map(d => d.avg_hours),
            backgroundColor: "#3b82f6"
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { labels: { color: "#e5e7eb" } } },
        scales: {
          x: { ticks: { color: "#9ca3af" }, grid: { color: "rgba(55, 65, 81, 0.3)" } },
          y: { ticks: { color: "#9ca3af" }, grid: { color: "rgba(55, 65, 81, 0.3)" }, title: { display: true, text: "Hours", color: "#9ca3af" } }
        }
      }
    });
  }

  // Chart 3: Stage Latency Breakdown
  const ctxStage = document.getElementById("stageChart");
  if (ctxStage) {
    charts.stage = new Chart(ctxStage, {
      type: "bar",
      data: {
        labels: analyticsData.stages.map(s => s.onboarding_stage.split(".")[1].trim()),
        datasets: [
          {
            label: "Queue Wait Delay (hrs)",
            data: analyticsData.stages.map(s => s.avg_queue_hours),
            backgroundColor: "#f59e0b"
          },
          {
            label: "Active Handling Duration (hrs)",
            data: analyticsData.stages.map(s => s.avg_handling_hours),
            backgroundColor: "#06b6d4"
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          x: { stacked: true, ticks: { color: "#9ca3af" }, grid: { color: "rgba(55, 65, 81, 0.3)" } },
          y: { stacked: true, ticks: { color: "#9ca3af" }, grid: { color: "rgba(55, 65, 81, 0.3)" }, title: { display: true, text: "Total Stage Latency (hrs)", color: "#9ca3af" } }
        },
        plugins: { legend: { labels: { color: "#e5e7eb" } } }
      }
    });
  }

  // Chart 4: Top Issues
  const ctxTopIssues = document.getElementById("topIssuesChart");
  if (ctxTopIssues) {
    charts.topIssues = new Chart(ctxTopIssues, {
      type: "bar",
      data: {
        labels: analyticsData.top_issues.map(i => i.issue.length > 20 ? i.issue.substring(0, 18) + "..." : i.issue),
        datasets: [{
          label: "Financial Waste ($ USD)",
          data: analyticsData.top_issues.map(i => i.cost),
          backgroundColor: "#8b5cf6"
        }]
      },
      options: {
        indexAxis: "y",
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          x: { ticks: { color: "#9ca3af", callback: v => `$${(v/1000).toFixed(0)}k` }, grid: { color: "rgba(55, 65, 81, 0.3)" } },
          y: { ticks: { color: "#9ca3af" }, grid: { color: "rgba(55, 65, 81, 0.3)" } }
        },
        plugins: { legend: { labels: { color: "#e5e7eb" } } }
      }
    });
  }

  // Chart 5: Hourly Arrival vs Staffing
  const ctxHourly = document.getElementById("hourlyArrivalChart");
  if (ctxHourly) {
    const hours = analyticsData.hourly_distribution.map(h => `${h.hour}:00`);
    charts.hourly = new Chart(ctxHourly, {
      type: "line",
      data: {
        labels: hours,
        datasets: [
          {
            label: "Incoming Volume (% of Daily)",
            data: analyticsData.hourly_distribution.map(h => h.volume_pct),
            borderColor: "#06b6d4",
            backgroundColor: "rgba(6, 182, 212, 0.15)",
            fill: true,
            tension: 0.3,
            yAxisID: "y"
          },
          {
            label: "Proposed Peak Shift Bandwidth (Staff)",
            data: analyticsData.hourly_distribution.map(h => h.proposed_staff),
            borderColor: "#10b981",
            borderDash: [5, 5],
            yAxisID: "y1"
          },
          {
            label: "Baseline Flat Staffing (Staff)",
            data: analyticsData.hourly_distribution.map(h => h.baseline_staff),
            borderColor: "#f43f5e",
            borderDash: [3, 3],
            yAxisID: "y1"
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          x: { ticks: { color: "#9ca3af" }, grid: { color: "rgba(55, 65, 81, 0.3)" } },
          y: { position: "left", ticks: { color: "#06b6d4" }, grid: { color: "rgba(55, 65, 81, 0.3)" }, title: { display: true, text: "Volume %", color: "#06b6d4" } },
          y1: { position: "right", ticks: { color: "#10b981" }, grid: { drawOnChartArea: false }, title: { display: true, text: "Staff Assigned", color: "#10b981" } }
        },
        plugins: { legend: { labels: { color: "#e5e7eb" } } }
      }
    });
  }

  // Chart 6: Queue Simulation Backlog
  const ctxQueue = document.getElementById("queueSimulationChart");
  if (ctxQueue) {
    const hours = analyticsData.hourly_distribution.map(h => `${h.hour}:00`);
    charts.queue = new Chart(ctxQueue, {
      type: "line",
      data: {
        labels: hours,
        datasets: [
          {
            label: "Baseline Queue Buildup (Tickets)",
            data: analyticsData.hourly_distribution.map(h => h.baseline_q),
            borderColor: "#f43f5e",
            backgroundColor: "rgba(244, 63, 94, 0.1)",
            fill: true,
            tension: 0.2
          },
          {
            label: "Proposed Dynamic Queue (Tickets)",
            data: analyticsData.hourly_distribution.map(h => h.proposed_q),
            borderColor: "#10b981",
            backgroundColor: "rgba(16, 185, 129, 0.1)",
            fill: true,
            tension: 0.2
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          x: { ticks: { color: "#9ca3af" }, grid: { color: "rgba(55, 65, 81, 0.3)" } },
          y: { ticks: { color: "#9ca3af" }, grid: { color: "rgba(55, 65, 81, 0.3)" }, title: { display: true, text: "Tickets in Queue", color: "#9ca3af" } }
        },
        plugins: { legend: { labels: { color: "#e5e7eb" } } }
      }
    });
  }
}

// Guesstimate Interactive Calculator
function initCalculator() {
  const inputRate = document.getElementById("input-rate");
  const inputVolume = document.getElementById("input-volume");
  const inputHours = document.getElementById("input-hours");
  const inputYield = document.getElementById("input-yield");
  const inputCapex = document.getElementById("input-capex");

  if (!inputRate) return;

  function recalculate() {
    const rate = parseFloat(inputRate.value);
    const volume = parseInt(inputVolume.value);
    const hours = parseFloat(inputHours.value);
    const yieldPct = parseFloat(inputYield.value) / 100.0;
    const capex = parseFloat(inputCapex.value);

    // Update label text
    document.getElementById("val-rate").textContent = `$${rate}`;
    document.getElementById("val-volume").textContent = volume.toLocaleString();
    document.getElementById("val-hours").textContent = `${hours.toFixed(2)} hrs`;
    document.getElementById("val-yield").textContent = `${(yieldPct * 100).toFixed(0)}%`;
    document.getElementById("val-capex").textContent = `$${capex.toLocaleString()}`;

    // Mathematical Guesstimate Formulation
    const bottleneckRate = 0.246;
    const associatesLoopedIn = 2.8;
    const bottleneckTickets = volume * bottleneckRate;
    const totalLaborHours = bottleneckTickets * (hours * associatesLoopedIn);
    const grossCost = totalLaborHours * rate;
    const savings = grossCost * yieldPct;
    const netBenefit = savings - capex;
    const fteUnlocked = (totalLaborHours * yieldPct) / 2080.0;
    const roi = (netBenefit / capex) * 100.0;
    const paybackMonths = capex / (savings / 12.0);

    // Update Output Elements
    document.getElementById("calc-gross-cost").textContent = `$${Math.round(grossCost).toLocaleString()}`;
    document.getElementById("calc-savings").textContent = `$${Math.round(savings).toLocaleString()}`;
    document.getElementById("calc-net").textContent = `$${Math.round(netBenefit).toLocaleString()}`;
    document.getElementById("calc-fte").textContent = `${fteUnlocked.toFixed(1)} FTEs`;
    document.getElementById("calc-roi").textContent = `${Math.round(roi).toLocaleString()}%`;
    document.getElementById("calc-payback").textContent = `${paybackMonths.toFixed(1)} Months`;
  }

  [inputRate, inputVolume, inputHours, inputYield, inputCapex].forEach(inp => {
    inp.addEventListener("input", recalculate);
  });

  recalculate();
}

// SQL Viewer
function initSqlViewer() {
  const navBtns = document.querySelectorAll(".sql-nav-btn");
  const codeBlock = document.getElementById("sqlCodeBlock");
  const titleBlock = document.getElementById("sql-title");
  const descBlock = document.getElementById("sql-desc");
  const copyBtn = document.getElementById("copySqlBtn");

  const descriptions = {
    "sla": "Measures SLA breach rates using date-time functions and conditional aggregations across departments and cohorts.",
    "bottleneck": "Pinpoints exact operational steps where bottlenecks occur, dissecting queue wait vs. active processing delays.",
    "cte": "Chained Common Table Expressions (CTEs) segmenting ticket resolution times by issue type and department.",
    "peak": "Analyzes hourly arrival patterns, isolating the 10:00-15:00 peak surge where 67% of volume arrives.",
    "guesstimate": "Guesstimate financial model: manual hours spent per associate on unresolved tickets * volume * loaded rate.",
    "resource": "Data-backed resource allocation model redistributing team bandwidth based on peak request hours."
  };

  function selectSql(key) {
    if (SQL_SNIPPETS[key]) {
      codeBlock.textContent = SQL_SNIPPETS[key];
      titleBlock.textContent = `sql/${key}_query.sql`;
      descBlock.textContent = descriptions[key] || "SQL Query for cross-functional ticket analytics.";
    }
  }

  navBtns.forEach(btn => {
    btn.addEventListener("click", () => {
      navBtns.forEach(b => b.classList.remove("active"));
      btn.classList.add("active");
      selectSql(btn.dataset.sql);
    });
  });

  if (copyBtn) {
    copyBtn.addEventListener("click", () => {
      navigator.clipboard.writeText(codeBlock.textContent).then(() => {
        const orig = copyBtn.textContent;
        copyBtn.textContent = "Copied!";
        setTimeout(() => copyBtn.textContent = orig, 1800);
      });
    });
  }

  selectSql("sla");
}

