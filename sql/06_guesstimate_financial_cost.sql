-- ==============================================================================
-- 06_guesstimate_financial_cost.sql
-- System: Cross-Functional Workflow & Ticket Analytics System
-- Module: Vendor Operations Workflow Optimizer
-- Purpose: Guesstimate Integration - Estimate the financial cost of operational
--          bottlenecks by calculating manual hours spent per associate on
--          unresolved tickets multiplied by ticket volume. Proves exact cost
--          savings and ROI achieved from automating workflows.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Master Guesstimate Financial Cost Model: Cost of Bottlenecks by Department
-- Formula: Manual Hours per Associate * Associates Involved * Ticket Volume * Hourly Rate
-- ------------------------------------------------------------------------------
WITH EconomicParameters AS (
    SELECT
        35.00 AS fully_loaded_hourly_rate_usd,  -- Standard operational associate hourly labor rate
        0.75  AS automation_yield_potential,    -- 75% of manual triage automatable via OCR/API rules
        65000 AS workflow_tooling_capex_usd     -- One-time implementation cost of workflow automation
),
DepartmentalLaborCost AS (
    SELECT
        t.department,
        COUNT(*) AS total_ticket_volume,
        -- Volume of tickets suffering from operational friction
        COUNT(CASE WHEN t.sla_breached = 1 OR t.is_unresolved = 1 THEN 1 END) AS bottlenecked_ticket_volume,
        -- Average manual hours spent per associate on clean vs bottlenecked tickets
        ROUND(AVG(CASE WHEN t.sla_breached = 0 AND t.is_unresolved = 0 THEN t.manual_hours_spent END), 2) AS clean_manual_hours_per_assoc,
        ROUND(AVG(CASE WHEN t.sla_breached = 1 OR t.is_unresolved = 1 THEN t.manual_hours_spent END), 2) AS bottleneck_manual_hours_per_assoc,
        ROUND(AVG(CASE WHEN t.sla_breached = 1 OR t.is_unresolved = 1 THEN t.associates_involved END), 1) AS avg_associates_looped_in,
        -- Total person-hours spent across all tickets
        ROUND(SUM(t.manual_hours_spent * t.associates_involved), 1) AS total_person_hours_consumed,
        -- Person-hours spent specifically resolving bottlenecks and rework
        ROUND(SUM(CASE 
            WHEN t.sla_breached = 1 OR t.is_unresolved = 1 
            THEN t.manual_hours_spent * t.associates_involved 
            ELSE 0 
        END), 1) AS bottleneck_person_hours_consumed
    FROM operational_tickets t
    GROUP BY t.department
)
SELECT
    d.department,
    d.total_ticket_volume,
    d.bottlenecked_ticket_volume,
    d.bottleneck_manual_hours_per_assoc,
    d.avg_associates_looped_in,
    d.bottleneck_person_hours_consumed,
    -- Financial Cost Calculation: Person Hours * Loaded Rate
    ROUND(d.bottleneck_person_hours_consumed * p.fully_loaded_hourly_rate_usd, 2) AS financial_cost_of_bottlenecks_usd,
    -- Exact Cost Savings of Automating 75% of Bottlenecked Workflow
    ROUND(d.bottleneck_person_hours_consumed * p.fully_loaded_hourly_rate_usd * p.automation_yield_potential, 2) AS projected_automation_savings_usd
FROM DepartmentalLaborCost d
CROSS JOIN EconomicParameters p
ORDER BY financial_cost_of_bottlenecks_usd DESC;

-- ------------------------------------------------------------------------------
-- 2. Executive ROI Summary: Labor Savings, Automation CapEx, and Net Benefit
-- Proves execution excellence and business impact to executive leadership
-- ------------------------------------------------------------------------------
WITH SystemFinancials AS (
    SELECT
        COUNT(*) AS total_tickets,
        COUNT(CASE WHEN sla_breached = 1 OR is_unresolved = 1 THEN 1 END) AS total_bottlenecked_tickets,
        SUM(manual_hours_spent * associates_involved) AS grand_total_person_hours,
        SUM(CASE 
            WHEN sla_breached = 1 OR is_unresolved = 1 
            THEN manual_hours_spent * associates_involved 
            ELSE 0 
        END) AS grand_total_bottleneck_hours,
        35.00 AS hourly_rate,
        0.75 AS automation_yield,
        65000.0 AS implementation_cost
    FROM operational_tickets
)
SELECT
    total_tickets,
    total_bottlenecked_tickets,
    ROUND(grand_total_bottleneck_hours, 1) AS annual_bottleneck_person_hours,
    -- Financial cost of manual friction
    ROUND(grand_total_bottleneck_hours * hourly_rate, 2) AS total_cost_of_bottlenecks_usd,
    -- Direct annual savings through workflow automation & simplification
    ROUND(grand_total_bottleneck_hours * hourly_rate * automation_yield, 2) AS annualized_cost_savings_usd,
    implementation_cost AS automation_implementation_cost_usd,
    -- Net Year 1 Profit / Benefit
    ROUND((grand_total_bottleneck_hours * hourly_rate * automation_yield) - implementation_cost, 2) AS net_year1_financial_benefit_usd,
    -- Return on Investment (ROI %)
    ROUND((((grand_total_bottleneck_hours * hourly_rate * automation_yield) - implementation_cost) / implementation_cost) * 100.0, 1) AS year1_roi_percentage,
    -- Payback period in months
    ROUND((implementation_cost / ((grand_total_bottleneck_hours * hourly_rate * automation_yield) / 12.0)), 1) AS payback_period_months
FROM SystemFinancials;

-- ------------------------------------------------------------------------------
-- 3. Top 5 Costliest Bottleneck Issue Types (High-Priority Automation Targets)
-- Identifies the specific workflows to automate first for maximum ROI
-- ------------------------------------------------------------------------------
SELECT
    issue_type,
    department,
    COUNT(*) AS total_tickets,
    COUNT(CASE WHEN sla_breached = 1 THEN 1 END) AS breached_tickets,
    ROUND(AVG(manual_hours_spent), 2) AS avg_manual_hours_per_assoc,
    ROUND(AVG(associates_involved), 1) AS avg_associates,
    ROUND(SUM(manual_hours_spent * associates_involved), 1) AS total_labor_hours_wasted,
    ROUND(SUM(manual_hours_spent * associates_involved) * 35.00, 2) AS total_financial_waste_usd,
    ROUND(SUM(manual_hours_spent * associates_involved) * 35.00 * 0.75, 2) AS automation_savings_opportunity_usd
FROM operational_tickets
GROUP BY issue_type, department
ORDER BY total_financial_waste_usd DESC
LIMIT 5;

