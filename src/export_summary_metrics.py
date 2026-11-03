#!/usr/bin/env python3
"""
export_summary_metrics.py
-------------------------
Extracts aggregated analytics and metrics from SQLite into JSON format
for the interactive executive dashboard.
"""

import os
import json
import sqlite3
import pandas as pd

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH = os.path.join(PROJECT_ROOT, "data", "analytics.db")
OUTPUT_JSON = os.path.join(PROJECT_ROOT, "dashboard", "data.json")

def export_metrics():
    if not os.path.exists(DB_PATH):
        print(f"Error: Database {DB_PATH} not found. Run run_pipeline.py first.")
        return

    conn = sqlite3.connect(DB_PATH)

    # 1. Executive KPI Summary
    kpis = conn.execute("""
        WITH S AS (
            SELECT 
                COUNT(*) AS total_tickets,
                SUM(CASE WHEN sla_breached = 1 OR is_unresolved = 1 THEN manual_hours_spent * associates_involved ELSE 0 END) AS waste_hours
            FROM operational_tickets
        )
        SELECT 
            (SELECT COUNT(*) FROM operational_tickets) AS total_tickets,
            (SELECT ROUND(AVG(actual_resolution_hours), 2) FROM operational_tickets WHERE workflow_phase = 'Baseline (Q1 2026)') AS baseline_avg_hours,
            (SELECT ROUND(AVG(actual_resolution_hours), 2) FROM operational_tickets WHERE workflow_phase = 'Optimized (Q2 2026)') AS optimized_avg_hours,
            (SELECT ROUND(100.0 * SUM(sla_breached) / COUNT(*), 1) FROM operational_tickets WHERE workflow_phase = 'Baseline (Q1 2026)') AS baseline_breach_rate,
            (SELECT ROUND(100.0 * SUM(sla_breached) / COUNT(*), 1) FROM operational_tickets WHERE workflow_phase = 'Optimized (Q2 2026)') AS optimized_breach_rate,
            (SELECT ROUND(100.0 * COUNT(CASE WHEN blocker_reason = 'None' THEN 1 END) / COUNT(*), 1) FROM operational_tickets WHERE workflow_phase = 'Baseline (Q1 2026)') AS baseline_clean_rate,
            (SELECT ROUND(100.0 * COUNT(CASE WHEN blocker_reason = 'None' THEN 1 END) / COUNT(*), 1) FROM operational_tickets WHERE workflow_phase = 'Optimized (Q2 2026)') AS optimized_clean_rate,
            ROUND(S.waste_hours, 1) AS bottleneck_hours,
            ROUND(S.waste_hours * 35.0, 2) AS bottleneck_cost_usd,
            ROUND(S.waste_hours * 35.0 * 0.75, 2) AS automation_savings_usd,
            ROUND((S.waste_hours * 35.0 * 0.75) - 65000.0, 2) AS net_benefit_usd
        FROM S;
    """).fetchone()

    kpi_dict = {
        "total_tickets": kpis[0],
        "baseline_avg_hours": kpis[1],
        "optimized_avg_hours": kpis[2],
        "cycle_time_reduction_pct": round(((kpis[1] - kpis[2]) / kpis[1]) * 100.0, 1),
        "baseline_breach_rate": kpis[3],
        "optimized_breach_rate": kpis[4],
        "breach_rate_drop_pts": round(kpis[3] - kpis[4], 1),
        "baseline_clean_rate": kpis[5],
        "optimized_clean_rate": kpis[6],
        "clean_rate_lift_pts": round(kpis[6] - kpis[5], 1),
        "bottleneck_hours": kpis[7],
        "bottleneck_cost_usd": kpis[8],
        "automation_savings_usd": kpis[9],
        "net_benefit_usd": kpis[10]
    }

    # 2. Monthly Trend
    monthly_df = pd.read_sql_query("""
        SELECT
            strftime('%Y-%m', created_at) AS month,
            workflow_phase,
            COUNT(*) AS volume,
            ROUND(AVG(actual_resolution_hours), 1) AS avg_hours,
            ROUND(100.0 * SUM(sla_breached) / COUNT(*), 1) AS breach_rate
        FROM operational_tickets
        GROUP BY 1, 2
        ORDER BY month ASC;
    """, conn)

    # 3. Department Breakdown
    dept_df = pd.read_sql_query("""
        SELECT
            department,
            COUNT(*) AS total_tickets,
            ROUND(AVG(actual_resolution_hours), 1) AS avg_hours,
            ROUND(AVG(queue_wait_hours), 1) AS avg_queue_wait,
            ROUND(100.0 * SUM(sla_breached) / COUNT(*), 1) AS breach_rate_pct,
            ROUND(SUM(manual_hours_spent * associates_involved) * 35.0, 2) AS financial_labor_waste_usd
        FROM operational_tickets
        GROUP BY department
        ORDER BY avg_hours DESC;
    """, conn)

    # 4. Onboarding Stage Bottlenecks
    stage_df = pd.read_sql_query("""
        SELECT
            onboarding_stage,
            COUNT(*) AS volume,
            ROUND(AVG(queue_wait_hours), 1) AS avg_queue_hours,
            ROUND(AVG(actual_resolution_hours - queue_wait_hours), 1) AS avg_handling_hours,
            ROUND(AVG(actual_resolution_hours), 1) AS avg_total_hours,
            ROUND(100.0 * SUM(sla_breached) / COUNT(*), 1) AS breach_rate_pct
        FROM operational_tickets
        GROUP BY onboarding_stage
        ORDER BY onboarding_stage ASC;
    """, conn)

    # 5. Hourly Arrival & Shift Bandwidth
    hourly_df = pd.read_sql_query("""
        SELECT
            created_hour,
            COUNT(*) AS tickets_created,
            ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM operational_tickets), 2) AS volume_pct,
            ROUND(AVG(queue_wait_hours), 2) AS avg_queue_wait,
            CASE 
                WHEN created_hour BETWEEN 10 AND 14 THEN 5.25
                WHEN created_hour IN (8, 9, 15, 16) THEN 2.50
                WHEN created_hour BETWEEN 17 AND 19 THEN 1.40
                ELSE 0.25
            END AS proposed_staff,
            CASE 
                WHEN created_hour BETWEEN 8 AND 19 THEN 2.92
                ELSE 0.50
            END AS baseline_staff
        FROM operational_tickets
        GROUP BY created_hour
        ORDER BY created_hour ASC;
    """, conn)

    # 6. Blocker Clearance Across Stakeholders
    stakeholder_df = pd.read_sql_query("""
        WITH S AS (
            SELECT
                department,
                workflow_phase,
                ROUND(100.0 * COUNT(CASE WHEN blocker_reason = 'None' THEN 1 END) / COUNT(*), 1) AS clean_rate
            FROM operational_tickets
            WHERE department IN ('Legal & Compliance', 'Finance & Accounting', 'Catalog & Operations')
            GROUP BY department, workflow_phase
        )
        SELECT
            b.department,
            b.clean_rate AS baseline_clean_rate,
            o.clean_rate AS optimized_clean_rate,
            ROUND(o.clean_rate - b.clean_rate, 1) AS lift_percentage_points
        FROM S b
        JOIN S o ON b.department = o.department 
          AND b.workflow_phase = 'Baseline (Q1 2026)' 
          AND o.workflow_phase = 'Optimized (Q2 2026)'
        ORDER BY lift_percentage_points DESC;
    """, conn)

    # 7. Top Bottleneck Issue Types
    issues_df = pd.read_sql_query("""
        SELECT
            issue_type,
            department,
            COUNT(*) AS count,
            ROUND(AVG(actual_resolution_hours), 1) AS avg_hours,
            ROUND(100.0 * SUM(sla_breached) / COUNT(*), 1) AS breach_rate,
            ROUND(SUM(manual_hours_spent * associates_involved) * 35.0, 2) AS bottleneck_cost_usd
        FROM operational_tickets
        GROUP BY issue_type, department
        ORDER BY bottleneck_cost_usd DESC
        LIMIT 8;
    """, conn)

    data = {
        "kpis": kpi_dict,
        "monthly_trend": monthly_df.to_dict(orient="records"),
        "departments": dept_df.to_dict(orient="records"),
        "stages": stage_df.to_dict(orient="records"),
        "hourly_distribution": hourly_df.to_dict(orient="records"),
        "stakeholder_clearance": stakeholder_df.to_dict(orient="records"),
        "top_issues": issues_df.to_dict(orient="records")
    }

    os.makedirs(os.path.dirname(OUTPUT_JSON), exist_ok=True)
    with open(OUTPUT_JSON, "w") as f:
        json.dump(data, f, indent=2)

    conn.close()
    print(f"Exported dashboard data to {OUTPUT_JSON}")

if __name__ == "__main__":
    export_metrics()
