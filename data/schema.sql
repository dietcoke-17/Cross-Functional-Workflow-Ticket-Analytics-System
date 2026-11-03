-- ==============================================================================
-- Schema Definition: Operational Support & Vendor Onboarding Tickets
-- Database Target: SQLite 3 / PostgreSQL / DuckDB compatible
-- ==============================================================================

DROP TABLE IF EXISTS operational_tickets;

CREATE TABLE operational_tickets (
    ticket_id               VARCHAR(32) PRIMARY KEY,
    vendor_id               VARCHAR(32) NOT NULL,
    vendor_name             VARCHAR(128) NOT NULL,
    vendor_tier             VARCHAR(64) NOT NULL,
    department              VARCHAR(64) NOT NULL,
    onboarding_stage        VARCHAR(64) NOT NULL,
    issue_type              VARCHAR(128) NOT NULL,
    priority                VARCHAR(32) NOT NULL,
    created_at              TIMESTAMP NOT NULL,
    assigned_at             TIMESTAMP NOT NULL,
    resolved_at             TIMESTAMP,
    created_hour            INTEGER NOT NULL,
    created_day_of_week     VARCHAR(16) NOT NULL,
    is_peak_hour            INTEGER NOT NULL,
    queue_wait_hours        NUMERIC(10, 2) NOT NULL,
    sla_target_hours        INTEGER NOT NULL,
    actual_resolution_hours NUMERIC(10, 2) NOT NULL,
    sla_breached            INTEGER NOT NULL,
    manual_hours_spent      NUMERIC(10, 2) NOT NULL,
    associates_involved     INTEGER NOT NULL,
    status                  VARCHAR(32) NOT NULL,
    is_unresolved           INTEGER NOT NULL,
    blocker_reason          VARCHAR(128) NOT NULL,
    workflow_phase          VARCHAR(64) NOT NULL,
    cycle_time_days         NUMERIC(10, 2) NOT NULL
);

-- Strategic Indexes for High-Performance Analytical Queries
CREATE INDEX idx_tickets_dept ON operational_tickets(department);
CREATE INDEX idx_tickets_stage ON operational_tickets(onboarding_stage);
CREATE INDEX idx_tickets_created_at ON operational_tickets(created_at);
CREATE INDEX idx_tickets_phase ON operational_tickets(workflow_phase);
CREATE INDEX idx_tickets_breach ON operational_tickets(sla_breached);
CREATE INDEX idx_tickets_priority ON operational_tickets(priority);
CREATE INDEX idx_tickets_peak ON operational_tickets(is_peak_hour, created_hour);

-- ==============================================================================
-- Analytical Staging View: Pre-calculated metrics for downstream analysis
-- ==============================================================================
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
    -- Associate Labor Effort in Person-Hours
    (manual_hours_spent * associates_involved) AS total_person_hours_spent,
    -- Delay excess over SLA (0 if met)
    CASE 
        WHEN actual_resolution_hours > sla_target_hours 
        THEN ROUND(actual_resolution_hours - sla_target_hours, 2)
        ELSE 0.00
    END AS sla_delay_hours,
    -- Flag for Clean / Blocker-Free execution
    CASE 
        WHEN blocker_reason = 'None' THEN 1 
        ELSE 0 
    END AS is_clean_execution
FROM operational_tickets;

