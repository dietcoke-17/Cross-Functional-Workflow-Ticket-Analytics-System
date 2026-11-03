-- ==============================================================================
-- 04_department_resolution_cte.sql
-- System: Cross-Functional Workflow & Ticket Analytics System
-- Module: Resource Allocation & Workflow Simplification Engine
-- Purpose: Chained Common Table Expressions (CTEs) segmenting ticket resolution
--          times by issue type and department to evaluate operational efficiency.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Comprehensive Multi-Level CTE Segmentation
-- ------------------------------------------------------------------------------
WITH 
-- CTE 1: Base Ticket Metric Enrichment
TicketLevelEnrichment AS (
    SELECT
        ticket_id,
        department,
        issue_type,
        onboarding_stage,
        priority,
        workflow_phase,
        queue_wait_hours,
        actual_resolution_hours,
        sla_target_hours,
        sla_breached,
        manual_hours_spent,
        associates_involved,
        -- Queue delay ratio: fraction of turnaround spent idle in queue
        ROUND(queue_wait_hours / NULLIF(actual_resolution_hours, 0), 3) AS queue_delay_ratio,
        -- SLA variance in hours (positive = overdue)
        ROUND(actual_resolution_hours - sla_target_hours, 2) AS sla_variance_hours
    FROM operational_tickets
),

-- CTE 2: Department-Level Macro Aggregations
DepartmentSummary AS (
    SELECT
        department,
        COUNT(*) AS total_dept_tickets,
        ROUND(AVG(actual_resolution_hours), 2) AS dept_avg_resolution_hours,
        ROUND(AVG(queue_wait_hours), 2) AS dept_avg_queue_wait_hours,
        ROUND(MIN(actual_resolution_hours), 2) AS dept_min_resolution_hours,
        ROUND(MAX(actual_resolution_hours), 2) AS dept_max_resolution_hours,
        ROUND(100.0 * SUM(sla_breached) / COUNT(*), 2) AS dept_sla_breach_rate_pct,
        ROUND(AVG(manual_hours_spent), 2) AS dept_avg_manual_hours,
        SUM(actual_resolution_hours) AS dept_total_resolution_workload
    FROM TicketLevelEnrichment
    GROUP BY department
),

-- CTE 3: Granular Segmentation by Department and Issue Type
IssueTypeSegmentation AS (
    SELECT
        t.department,
        t.issue_type,
        t.onboarding_stage,
        COUNT(*) AS issue_ticket_volume,
        ROUND(100.0 * COUNT(*) / d.total_dept_tickets, 2) AS issue_dept_volume_share_pct,
        ROUND(AVG(t.actual_resolution_hours), 2) AS avg_resolution_hours,
        ROUND(AVG(t.queue_wait_hours), 2) AS avg_queue_wait_hours,
        ROUND(AVG(t.actual_resolution_hours - t.queue_wait_hours), 2) AS avg_active_work_hours,
        ROUND(100.0 * SUM(t.sla_breached) / COUNT(*), 2) AS issue_sla_breach_rate_pct,
        ROUND(AVG(t.manual_hours_spent * t.associates_involved), 2) AS avg_total_person_hours
    FROM TicketLevelEnrichment t
    JOIN DepartmentSummary d ON t.department = d.department
    GROUP BY t.department, t.issue_type, t.onboarding_stage, d.total_dept_tickets
),

-- CTE 4: Window Ranking of Issue Types within each Department
RankedDepartmentIssues AS (
    SELECT
        department,
        issue_type,
        onboarding_stage,
        issue_ticket_volume,
        issue_dept_volume_share_pct,
        avg_resolution_hours,
        avg_queue_wait_hours,
        avg_active_work_hours,
        issue_sla_breach_rate_pct,
        avg_total_person_hours,
        -- Intra-department resolution time ranking
        DENSE_RANK() OVER (
            PARTITION BY department 
            ORDER BY avg_resolution_hours DESC
        ) AS dept_latency_rank,
        -- Cross-system overall resolution time ranking
        DENSE_RANK() OVER (
            ORDER BY avg_resolution_hours DESC
        ) AS cross_system_latency_rank
    FROM IssueTypeSegmentation
)

-- Final SELECT: Exposes the full hierarchical segmentation
SELECT
    department,
    issue_type,
    onboarding_stage,
    dept_latency_rank,
    issue_ticket_volume,
    issue_dept_volume_share_pct,
    avg_resolution_hours,
    avg_queue_wait_hours,
    avg_active_work_hours,
    issue_sla_breach_rate_pct,
    avg_total_person_hours,
    cross_system_latency_rank
FROM RankedDepartmentIssues
ORDER BY department ASC, dept_latency_rank ASC;
