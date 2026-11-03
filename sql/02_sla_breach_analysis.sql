-- ==============================================================================
-- 02_sla_breach_analysis.sql
-- System: Cross-Functional Workflow & Ticket Analytics System
-- Module: Vendor Operations Workflow Optimizer
-- Purpose: Measure Service Level Agreement (SLA) breach rates using date-time
--          functions and conditional aggregations across departments and cohorts.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Monthly SLA Breach Trend Analysis (Temporal Cohorts)
-- Demonstrates date-time extraction and month-over-month performance tracking
-- ------------------------------------------------------------------------------
SELECT
    strftime('%Y-%m', created_at) AS report_month,
    workflow_phase,
    COUNT(*) AS total_ticket_volume,
    -- Conditional Aggregations for SLA compliance
    COUNT(CASE WHEN sla_breached = 0 THEN 1 END) AS tickets_within_sla,
    COUNT(CASE WHEN sla_breached = 1 THEN 1 END) AS tickets_breached_sla,
    ROUND(100.0 * COUNT(CASE WHEN sla_breached = 1 THEN 1 END) / COUNT(*), 2) AS sla_breach_rate_pct,
    -- Delay severity conditional calculations
    ROUND(AVG(actual_resolution_hours), 2) AS avg_resolution_hours,
    ROUND(AVG(CASE WHEN sla_breached = 1 THEN actual_resolution_hours - sla_target_hours ELSE NULL END), 2) AS avg_breach_overdue_hours,
    -- Volume of critical P1/P2 breaches
    COUNT(CASE WHEN priority IN ('P1 - Critical', 'P2 - High') AND sla_breached = 1 THEN 1 END) AS high_severity_breaches
FROM operational_tickets
GROUP BY strftime('%Y-%m', created_at), workflow_phase
ORDER BY report_month ASC;

-- ------------------------------------------------------------------------------
-- 2. Departmental SLA Breach Segmentation with Priority Cross-Tabulation
-- Evaluates department-level resolution times and identifies highest breach risk
-- ------------------------------------------------------------------------------
SELECT
    department,
    COUNT(*) AS total_tickets,
    -- Conditional aggregations by Priority level
    COUNT(CASE WHEN priority = 'P1 - Critical' THEN 1 END) AS p1_count,
    ROUND(100.0 * SUM(CASE WHEN priority = 'P1 - Critical' AND sla_breached = 1 THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(CASE WHEN priority = 'P1 - Critical' THEN 1 END), 0), 2) AS p1_breach_rate_pct,
    COUNT(CASE WHEN priority = 'P2 - High' THEN 1 END) AS p2_count,
    ROUND(100.0 * SUM(CASE WHEN priority = 'P2 - High' AND sla_breached = 1 THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(CASE WHEN priority = 'P2 - High' THEN 1 END), 0), 2) AS p2_breach_rate_pct,
    -- Overall SLA metrics
    SUM(sla_breached) AS total_breaches,
    ROUND(100.0 * SUM(sla_breached) / COUNT(*), 2) AS overall_breach_rate_pct,
    ROUND(AVG(actual_resolution_hours), 2) AS avg_resolution_hours,
    ROUND(MAX(actual_resolution_hours), 2) AS max_resolution_hours
FROM operational_tickets
GROUP BY department
ORDER BY overall_breach_rate_pct DESC;

-- ------------------------------------------------------------------------------
-- 3. Stage-Level SLA Breach Comparison: Baseline (Q1) vs Optimized (Q2)
-- Isolates the operational steps where interventions yielded largest reductions
-- ------------------------------------------------------------------------------
SELECT
    onboarding_stage,
    -- Baseline (Q1) Metrics
    COUNT(CASE WHEN workflow_phase = 'Baseline (Q1 2026)' THEN 1 END) AS baseline_volume,
    ROUND(100.0 * SUM(CASE WHEN workflow_phase = 'Baseline (Q1 2026)' AND sla_breached = 1 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(CASE WHEN workflow_phase = 'Baseline (Q1 2026)' THEN 1 END), 0), 2) AS baseline_breach_pct,
    ROUND(AVG(CASE WHEN workflow_phase = 'Baseline (Q1 2026)' THEN actual_resolution_hours END), 2) AS baseline_avg_hours,
    -- Optimized (Q2) Metrics
    COUNT(CASE WHEN workflow_phase = 'Optimized (Q2 2026)' THEN 1 END) AS optimized_volume,
    ROUND(100.0 * SUM(CASE WHEN workflow_phase = 'Optimized (Q2 2026)' AND sla_breached = 1 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(CASE WHEN workflow_phase = 'Optimized (Q2 2026)' THEN 1 END), 0), 2) AS optimized_breach_pct,
    ROUND(AVG(CASE WHEN workflow_phase = 'Optimized (Q2 2026)' THEN actual_resolution_hours END), 2) AS optimized_avg_hours,
    -- Net SLA Breach Rate Improvement (Percentage Points Delta)
    ROUND(
        (100.0 * SUM(CASE WHEN workflow_phase = 'Baseline (Q1 2026)' AND sla_breached = 1 THEN 1 ELSE 0 END) /
         NULLIF(COUNT(CASE WHEN workflow_phase = 'Baseline (Q1 2026)' THEN 1 END), 0)) -
        (100.0 * SUM(CASE WHEN workflow_phase = 'Optimized (Q2 2026)' AND sla_breached = 1 THEN 1 ELSE 0 END) /
         NULLIF(COUNT(CASE WHEN workflow_phase = 'Optimized (Q2 2026)' THEN 1 END), 0)),
        2
    ) AS breach_rate_reduction_pts
FROM operational_tickets
GROUP BY onboarding_stage
ORDER BY onboarding_stage ASC;

