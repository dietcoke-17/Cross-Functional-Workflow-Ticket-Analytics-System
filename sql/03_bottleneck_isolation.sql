-- ==============================================================================
-- 03_bottleneck_isolation.sql
-- System: Cross-Functional Workflow & Ticket Analytics System
-- Module: Vendor Operations Workflow Optimizer
-- Purpose: Pinpoint exact operational steps where bottlenecks occur, dissect
--          queue wait vs. active processing delays, and evaluate blocker impact.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Operational Step Bottleneck Hierarchy: Stage Cycle Time & Queue Delay
-- Isolates the stages contributing the greatest share of vendor onboarding latency
-- ------------------------------------------------------------------------------
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
),
TotalLatency AS (
    SELECT SUM(actual_resolution_hours) AS grand_total_hours FROM operational_tickets
)
SELECT
    s.onboarding_stage,
    s.stage_ticket_volume,
    s.avg_queue_wait_hours,
    s.avg_active_handling_hours,
    s.avg_total_cycle_hours,
    s.stage_sla_breach_rate,
    -- Percentage of total operational friction originating in this stage
    ROUND(100.0 * s.sum_total_hours / t.grand_total_hours, 2) AS pct_of_total_organization_delay,
    -- Bottleneck Severity Rank
    DENSE_RANK() OVER (ORDER BY s.avg_total_cycle_hours DESC) AS bottleneck_severity_rank
FROM StageMetrics s
CROSS JOIN TotalLatency t
ORDER BY s.avg_total_cycle_hours DESC;

-- ------------------------------------------------------------------------------
-- 2. Root Cause Blocker Analysis Across Key Stakeholder Functions
-- Evaluates the frequency, resolution impact, and manual effort of blockers
-- ------------------------------------------------------------------------------
SELECT
    blocker_reason,
    COUNT(*) AS incident_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM operational_tickets), 2) AS incident_frequency_pct,
    ROUND(AVG(actual_resolution_hours), 2) AS avg_resolution_hours_with_blocker,
    ROUND(AVG(manual_hours_spent), 2) AS avg_manual_hours_per_associate,
    ROUND(AVG(associates_involved), 2) AS avg_associates_looped_in,
    ROUND(100.0 * SUM(sla_breached) / COUNT(*), 2) AS sla_breach_rate_pct
FROM operational_tickets
GROUP BY blocker_reason
ORDER BY incident_count DESC;

-- ------------------------------------------------------------------------------
-- 3. Cross-Functional Implementation Success Rate: Baseline vs Optimized
-- Quantifies the 20% improvement in blocker removal achieved through coordination
-- across the 3 key stakeholder functions (Legal, Finance, Catalog)
-- ------------------------------------------------------------------------------
WITH BlockerClearanceByStakeholder AS (
    SELECT
        department,
        workflow_phase,
        COUNT(*) AS total_tickets,
        COUNT(CASE WHEN blocker_reason = 'None' THEN 1 END) AS clean_first_pass_tickets,
        ROUND(100.0 * COUNT(CASE WHEN blocker_reason = 'None' THEN 1 END) / COUNT(*), 2) AS first_pass_success_rate
    FROM operational_tickets
    WHERE department IN ('Legal & Compliance', 'Finance & Accounting', 'Catalog & Operations')
    GROUP BY department, workflow_phase
)
SELECT
    b.department,
    b.first_pass_success_rate AS baseline_success_rate_pct,
    o.first_pass_success_rate AS optimized_success_rate_pct,
    ROUND(o.first_pass_success_rate - b.first_pass_success_rate, 2) AS net_improvement_percentage_points,
    ROUND(((o.first_pass_success_rate - b.first_pass_success_rate) / b.first_pass_success_rate) * 100.0, 2) AS relative_lift_pct
FROM BlockerClearanceByStakeholder b
JOIN BlockerClearanceByStakeholder o
  ON b.department = o.department
 AND b.workflow_phase = 'Baseline (Q1 2026)'
 AND o.workflow_phase = 'Optimized (Q2 2026)'
ORDER BY net_improvement_percentage_points DESC;
