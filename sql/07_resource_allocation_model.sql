-- ==============================================================================
-- 07_resource_allocation_model.sql
-- System: Cross-Functional Workflow & Ticket Analytics System
-- Module: Resource Allocation & Workflow Simplification Engine
-- Purpose: Data-backed resource allocation model redistributing team bandwidth
--          based on peak request hours, quantifying queue reduction and proving
--          the 25% reduction in vendor onboarding workflow times.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Hourly Capacity vs Demand: Uniform vs Dynamic Reallocation
-- Demonstrates how redistributing 35 total headcount solves peak queue buildup
-- ------------------------------------------------------------------------------
WITH HourlyDemand AS (
    SELECT
        created_hour,
        COUNT(*) AS total_tickets,
        ROUND(COUNT(*) / 181.0, 1) AS avg_tickets_per_hour_daily,
        ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM operational_tickets), 2) AS demand_share_pct
    FROM operational_tickets
    GROUP BY created_hour
),
StaffingAllocationModel AS (
    SELECT
        h.created_hour,
        h.total_tickets,
        h.avg_tickets_per_hour_daily,
        h.demand_share_pct,
        -- Baseline: Flat uniform allocation across 12 operational hours (08:00 - 20:00)
        -- Total pool: 35 associates (~2.9 associates per hour)
        CASE 
            WHEN h.created_hour BETWEEN 8 AND 19 THEN 2.92
            ELSE 0.50 
        END AS baseline_headcount_allocated,
        -- Proposed Dynamic Allocation: Staggered shifts aligning capacity with demand curve
        -- Peak surge (10:00 - 14:59) boosted to 5.25 associates/hour
        -- Off-peak hours reduced to 1.40 associates/hour
        CASE 
            WHEN h.created_hour BETWEEN 10 AND 14 THEN 5.25  -- Peak Surge Squad
            WHEN h.created_hour IN (8, 9, 15, 16) THEN 2.50  -- Shoulder Shift
            WHEN h.created_hour BETWEEN 17 AND 19 THEN 1.40  -- Evening Wrap-up
            ELSE 0.25                                       -- Night Monitoring
        END AS proposed_headcount_allocated
    FROM HourlyDemand h
)
SELECT
    created_hour,
    avg_tickets_per_hour_daily,
    demand_share_pct,
    baseline_headcount_allocated,
    -- Associate processing capacity at 1.4 tickets/associate/hour
    ROUND(baseline_headcount_allocated * 1.4, 1) AS baseline_processing_capacity_per_hr,
    ROUND(avg_tickets_per_hour_daily - (baseline_headcount_allocated * 1.4), 1) AS baseline_hourly_queue_surplus_deficit,
    proposed_headcount_allocated,
    ROUND(proposed_headcount_allocated * 1.4, 1) AS proposed_processing_capacity_per_hr,
    ROUND(avg_tickets_per_hour_daily - (proposed_headcount_allocated * 1.4), 1) AS proposed_hourly_balance
FROM StaffingAllocationModel
ORDER BY created_hour ASC;

-- ------------------------------------------------------------------------------
-- 2. Empirical Verification: Workflow Cycle Time Reduction (25% Improvement)
-- Compares Baseline (Q1) vs Optimized (Q2) overall and across central functions
-- ------------------------------------------------------------------------------
WITH PhaseComparison AS (
    SELECT
        department,
        workflow_phase,
        COUNT(*) AS ticket_volume,
        ROUND(AVG(queue_wait_hours), 2) AS avg_queue_wait_hours,
        ROUND(AVG(actual_resolution_hours), 2) AS avg_resolution_hours,
        ROUND(AVG(cycle_time_days), 2) AS avg_cycle_time_days,
        ROUND(100.0 * SUM(sla_breached) / COUNT(*), 2) AS sla_breach_rate_pct
    FROM operational_tickets
    GROUP BY department, workflow_phase
)
SELECT
    b.department,
    b.ticket_volume AS baseline_volume,
    b.avg_resolution_hours AS baseline_avg_hours,
    o.avg_resolution_hours AS optimized_avg_hours,
    -- Cycle time hours reduced
    ROUND(b.avg_resolution_hours - o.avg_resolution_hours, 2) AS hours_saved_per_ticket,
    -- Percentage reduction in turnaround time
    ROUND(((b.avg_resolution_hours - o.avg_resolution_hours) / b.avg_resolution_hours) * 100.0, 1) AS workflow_time_reduction_pct,
    -- SLA breach rate delta
    b.sla_breach_rate_pct AS baseline_breach_pct,
    o.sla_breach_rate_pct AS optimized_breach_pct,
    ROUND(b.sla_breach_rate_pct - o.sla_breach_rate_pct, 1) AS breach_rate_drop_pts
FROM PhaseComparison b
JOIN PhaseComparison o
  ON b.department = o.department
 AND b.workflow_phase = 'Baseline (Q1 2026)'
 AND o.workflow_phase = 'Optimized (Q2 2026)'
ORDER BY workflow_time_reduction_pct DESC;

-- ------------------------------------------------------------------------------
-- 3. System-Wide Executive Impact Summary: 25% Reduction Milestone Proof
-- ------------------------------------------------------------------------------
SELECT
    'System-Wide Vendor Operations' AS scope,
    ROUND(AVG(CASE WHEN workflow_phase = 'Baseline (Q1 2026)' THEN actual_resolution_hours END), 2) AS baseline_avg_resolution_hours,
    ROUND(AVG(CASE WHEN workflow_phase = 'Optimized (Q2 2026)' THEN actual_resolution_hours END), 2) AS optimized_avg_resolution_hours,
    ROUND(
        ((AVG(CASE WHEN workflow_phase = 'Baseline (Q1 2026)' THEN actual_resolution_hours END) -
          AVG(CASE WHEN workflow_phase = 'Optimized (Q2 2026)' THEN actual_resolution_hours END)) /
         AVG(CASE WHEN workflow_phase = 'Baseline (Q1 2026)' THEN actual_resolution_hours END)) * 100.0,
        1
    ) AS verified_cycle_time_reduction_pct,
    ROUND(AVG(CASE WHEN workflow_phase = 'Baseline (Q1 2026)' THEN queue_wait_hours END), 2) AS baseline_avg_queue_wait_hours,
    ROUND(AVG(CASE WHEN workflow_phase = 'Optimized (Q2 2026)' THEN queue_wait_hours END), 2) AS optimized_avg_queue_wait_hours,
    ROUND(
        ((AVG(CASE WHEN workflow_phase = 'Baseline (Q1 2026)' THEN queue_wait_hours END) -
          AVG(CASE WHEN workflow_phase = 'Optimized (Q2 2026)' THEN queue_wait_hours END)) /
         AVG(CASE WHEN workflow_phase = 'Baseline (Q1 2026)' THEN queue_wait_hours END)) * 100.0,
        1
    ) AS queue_wait_reduction_pct
FROM operational_tickets;
