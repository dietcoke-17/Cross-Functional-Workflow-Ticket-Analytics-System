#!/usr/bin/env python3
"""
test_analytics.py
-----------------
Automated test suite validating data integrity, SQL output metrics,
and verified business milestones for the Cross-Functional Workflow
& Ticket Analytics System.
"""

import os
import unittest
import sqlite3
import pandas as pd

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(PROJECT_ROOT, "data")
CSV_PATH = os.path.join(DATA_DIR, "raw_tickets_10k.csv")
DB_PATH = os.path.join(DATA_DIR, "analytics.db")

class TestWorkflowAnalytics(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        """Ensures the dataset and database are present prior to tests."""
        cls.assertTrue(cls, os.path.exists(CSV_PATH), f"CSV dataset not found at {CSV_PATH}")
        cls.assertTrue(cls, os.path.exists(DB_PATH), f"Database not found at {DB_PATH}")
        cls.conn = sqlite3.connect(DB_PATH)

    @classmethod
    def tearDownClass(cls):
        cls.conn.close()

    def test_01_dataset_volume_and_schema(self):
        """Milestone Check: Analyzed 10,000+ operational support tickets."""
        df = pd.read_csv(CSV_PATH, keep_default_na=False)
        self.assertGreaterEqual(len(df), 10000, "Dataset must contain at least 10,000 tickets")
        self.assertEqual(len(df), 10500, "Expected exactly 10,500 tickets in standardized dataset")

        required_cols = [
            "ticket_id", "vendor_id", "vendor_tier", "department",
            "onboarding_stage", "issue_type", "priority", "created_at",
            "assigned_at", "actual_resolution_hours", "sla_breached",
            "manual_hours_spent", "associates_involved", "workflow_phase"
        ]
        for col in required_cols:
            self.assertIn(col, df.columns, f"Missing required column: {col}")

    def test_02_department_representation(self):
        """Verifies cross-functional distribution across 5 Central functions."""
        cursor = self.conn.cursor()
        depts = [row[0] for row in cursor.execute("SELECT DISTINCT department FROM operational_tickets;").fetchall()]
        expected_depts = [
            "Legal & Compliance",
            "Finance & Accounting",
            "Catalog & Operations",
            "Technical Support",
            "Central Vendor Operations"
        ]
        for dept in expected_depts:
            self.assertIn(dept, depts, f"Missing expected department: {dept}")

    def test_03_cycle_time_reduction_milestone(self):
        """Milestone Check: Reducing vendor onboarding workflow times by 25%."""
        cursor = self.conn.cursor()
        b_avg = cursor.execute("""
            SELECT AVG(actual_resolution_hours) 
            FROM operational_tickets 
            WHERE workflow_phase = 'Baseline (Q1 2026)';
        """).fetchone()[0]

        o_avg = cursor.execute("""
            SELECT AVG(actual_resolution_hours) 
            FROM operational_tickets 
            WHERE workflow_phase = 'Optimized (Q2 2026)';
        """).fetchone()[0]

        reduction_pct = ((b_avg - o_avg) / b_avg) * 100.0
        print(f"\n[TEST INFO] Verified Workflow Time Reduction: {reduction_pct:.2f}% (Target: ~25.0%)")
        self.assertTrue(24.0 <= reduction_pct <= 27.0, f"Reduction {reduction_pct:.2f}% not within target 24%-27% range")

    def test_04_blocker_clearance_milestone(self):
        """Milestone Check: Coordinated across 3 stakeholders, improving implementation success rates by 20%."""
        cursor = self.conn.cursor()
        stakeholder_lift = cursor.execute("""
            WITH S AS (
                SELECT
                    workflow_phase,
                    ROUND(100.0 * COUNT(CASE WHEN blocker_reason = 'None' THEN 1 END) / COUNT(*), 2) AS clean_rate
                FROM operational_tickets
                WHERE department IN ('Legal & Compliance', 'Finance & Accounting', 'Catalog & Operations')
                GROUP BY workflow_phase
            )
            SELECT 
                (SELECT clean_rate FROM S WHERE workflow_phase = 'Optimized (Q2 2026)') -
                (SELECT clean_rate FROM S WHERE workflow_phase = 'Baseline (Q1 2026)') AS lift;
        """).fetchone()[0]

        print(f"[TEST INFO] Verified Stakeholder Success Rate Lift: +{stakeholder_lift:.2f} percentage points (Target: ~20%)")
        self.assertTrue(18.0 <= stakeholder_lift <= 22.0, f"Lift {stakeholder_lift:.2f} pts not within target 18-22 pts range")

    def test_05_peak_hour_surge_concentration(self):
        """Verifies that peak hours (10:00 - 15:00) represent the dominant influx (>60%)."""
        cursor = self.conn.cursor()
        peak_share = cursor.execute("""
            SELECT ROUND(100.0 * COUNT(CASE WHEN is_peak_hour = 1 THEN 1 END) / COUNT(*), 2)
            FROM operational_tickets;
        """).fetchone()[0]

        print(f"[TEST INFO] Peak Influx Concentration: {peak_share:.2f}% of daily volume")
        self.assertGreaterEqual(peak_share, 60.0, "Peak hours must represent >= 60% of influx")

    def test_06_guesstimate_financial_model(self):
        """Verifies the Guesstimate financial calculation logic and positive ROI."""
        cursor = self.conn.cursor()
        res = cursor.execute("""
            WITH S AS (
                SELECT SUM(manual_hours_spent * associates_involved) AS waste_hours
                FROM operational_tickets
                WHERE sla_breached = 1 OR is_unresolved = 1
            )
            SELECT 
                waste_hours,
                waste_hours * 35.0 AS cost_usd,
                waste_hours * 35.0 * 0.75 AS savings_usd
            FROM S;
        """).fetchone()

        waste_hours, cost_usd, savings_usd = res
        self.assertGreater(waste_hours, 20000, "Expected > 20,000 person-hours of bottleneck waste")
        self.assertGreater(cost_usd, 700000, "Expected > $700,000 gross bottleneck cost")
        self.assertGreater(savings_usd, 500000, "Expected > $500,000 in projected savings")

if __name__ == "__main__":
    unittest.main()

