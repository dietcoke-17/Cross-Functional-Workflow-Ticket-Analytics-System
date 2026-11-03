-- ==============================================================================
-- 01_schema_and_views.sql
-- System: Cross-Functional Workflow & Ticket Analytics System
-- Purpose: Schema verification, staging views, and base analytical transformations
-- ==============================================================================

-- Staging View with Date-Time Enrichments and Derived Flags
DROP VIEW IF EXISTS v_ticket_analytics_base;

CREATE VIEW v_ticket_analytics_base AS
SELECT
    ticket_id,
    vendor_id,
    vendor_name,
    vendor_tier,
    department,
    onboarding_stage,
    issue_type,
    priority,
    created_at,
    assigned_at,
    resolved_at,
    created_hour,
    created_day_of_week,
    is_peak_hour,
    queue_wait_hours,
    sla_target_hours,
    actual_resolution_hours,
    sla_breached,
    manual_hours_spent,
    associates_involved,
    status,
    is_unresolved,
    blocker_reason,
    workflow_phase,
    cycle_time_days,
    -- Date-time functions for temporal cohort analysis
    strftime('%Y-%m', created_at) AS created_month,
    strftime('%Y-%W', created_at) AS created_week,
    -- Total labor effort (associate-hours)
    ROUND(manual_hours_spent * associates_involved, 2) AS total_labor_hours,
    -- Excess delay hours beyond SLA threshold
    CASE 
        WHEN actual_resolution_hours > sla_target_hours 
        THEN ROUND(actual_resolution_hours - sla_target_hours, 2)
        ELSE 0.00
    END AS sla_overdue_hours,
    -- Implementation success / First-pass clean execution flag
    CASE 
        WHEN blocker_reason = 'None' THEN 1 
        ELSE 0 
    END AS is_first_pass_clean
FROM operational_tickets;

-- Verification Check Query
SELECT 
    workflow_phase,
    COUNT(*) AS total_tickets,
    ROUND(AVG(actual_resolution_hours), 2) AS avg_resolution_hours,
    ROUND(100.0 * SUM(sla_breached) / COUNT(*), 2) AS sla_breach_rate_pct,
    ROUND(100.0 * SUM(is_first_pass_clean) / COUNT(*), 2) AS first_pass_success_pct
FROM v_ticket_analytics_base
GROUP BY workflow_phase
ORDER BY workflow_phase;

