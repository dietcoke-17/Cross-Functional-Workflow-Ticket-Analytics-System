-- ==============================================================================
-- 05_peak_hours_bandwidth.sql
-- System: Cross-Functional Workflow & Ticket Analytics System
-- Module: Resource Allocation & Workflow Simplification Engine
-- Purpose: Analyze ticket arrival patterns by hour of day and day of week,
--          identifying demand surges and capacity mismatch driving queue delays.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Hourly Arrival Distribution and Queue Congestion Matrix
-- ------------------------------------------------------------------------------
WITH HourlyArrivalStats AS (
    SELECT
        created_hour,
        COUNT(*) AS tickets_created,
        ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM operational_tickets), 2) AS pct_of_daily_volume,
        ROUND(AVG(queue_wait_hours), 2) AS avg_queue_wait_hours,
        ROUND(AVG(actual_resolution_hours), 2) AS avg_resolution_hours,
        SUM(sla_breached) AS sla_breaches_incurred,
        ROUND(100.0 * SUM(sla_breached) / COUNT(*), 2) AS hourly_breach_rate_pct,
        -- Operational Shift Tag
        CASE 
            WHEN created_hour BETWEEN 10 AND 14 THEN 'Peak Surge Window (10:00-14:59)'
            WHEN created_hour IN (8, 9, 15, 16) THEN 'Shoulder Shift (08:00-09:59, 15:00-16:59)'
            ELSE 'Off-Peak / Night (17:00-07:59)'
        END AS shift_window
    FROM operational_tickets
    GROUP BY created_hour
)
SELECT
    created_hour,
    shift_window,
    tickets_created,
    pct_of_daily_volume,
    avg_queue_wait_hours,
    avg_resolution_hours,
    sla_breaches_incurred,
    hourly_breach_rate_pct,
    -- Volume vs Baseline Expected (assuming uniform 4.17% per hour)
    ROUND((pct_of_daily_volume - 4.17) / 4.17 * 100.0, 1) AS demand_surge_vs_uniform_pct
FROM HourlyArrivalStats
ORDER BY created_hour ASC;

-- ------------------------------------------------------------------------------
-- 2. Shift Window Macro Comparison: Peak Surge vs Shoulder vs Off-Peak
-- Quantifies why uniform staffing failed and where bandwidth redistribution is needed
-- ------------------------------------------------------------------------------
SELECT
    CASE 
        WHEN created_hour BETWEEN 10 AND 14 THEN 'Peak Surge (10:00 - 15:00)'
        WHEN created_hour BETWEEN 8 AND 9 OR created_hour BETWEEN 15 AND 18 THEN 'Standard Business Hours'
        ELSE 'Off-Hours & Weekends'
    END AS operational_window,
    COUNT(*) AS total_ticket_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM operational_tickets), 1) AS volume_share_pct,
    ROUND(AVG(queue_wait_hours), 2) AS avg_queue_wait_hours,
    ROUND(AVG(actual_resolution_hours), 2) AS avg_resolution_hours,
    ROUND(100.0 * SUM(sla_breached) / COUNT(*), 2) AS breach_rate_pct,
    ROUND(100.0 * SUM(sla_breached) / (SELECT SUM(sla_breached) FROM operational_tickets), 1) AS pct_of_all_breaches_in_system
FROM operational_tickets
GROUP BY 1
ORDER BY total_ticket_count DESC;

-- ------------------------------------------------------------------------------
-- 3. Day of Week Arrival Distribution Across Central Functions
-- Pinpoints weekday vs weekend workflow cadence
-- ------------------------------------------------------------------------------
SELECT
    created_day_of_week,
    COUNT(*) AS total_tickets,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM operational_tickets), 1) AS weekday_volume_share_pct,
    ROUND(AVG(actual_resolution_hours), 2) AS avg_resolution_hours,
    ROUND(100.0 * SUM(sla_breached) / COUNT(*), 2) AS breach_rate_pct
FROM operational_tickets
GROUP BY created_day_of_week
ORDER BY 
    CASE created_day_of_week
        WHEN 'Monday' THEN 1
        WHEN 'Tuesday' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4
        WHEN 'Friday' THEN 5
        WHEN 'Saturday' THEN 6
        WHEN 'Sunday' THEN 7
    END ASC;

