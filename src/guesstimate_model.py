#!/usr/bin/env python3
"""
guesstimate_model.py
--------------------
Parametric financial estimation and ROI modeling engine.
Implements the Guesstimate framework for operational bottleneck quantification:
  Cost = Ticket Volume * Bottleneck Rate * Manual Hours per Associate * Associates * Hourly Labor Rate
Provides sensitivity matrix analysis, automation ROI, and payback period calculation.
"""

import argparse
import numpy as np
import pandas as pd

class GuesstimateFinancialEngine:
    def __init__(
        self,
        annual_tickets=10500,
        bottleneck_rate=0.246,          # 24.6% of tickets incur severe rework/SLA breaches
        manual_hours_per_assoc=3.85,    # Manual triage & email back-and-forth per associate
        associates_per_ticket=2.8,      # Average associates looped in per unresolved ticket
        hourly_wage_usd=35.0,           # Fully loaded cost per operational associate ($/hr)
        automation_yield=0.75,          # 75% of repetitive document/data tasks automatable
        tooling_capex_usd=65000.0       # One-time integration and workflow tooling investment
    ):
        self.annual_tickets = annual_tickets
        self.bottleneck_rate = bottleneck_rate
        self.manual_hours_per_assoc = manual_hours_per_assoc
        self.associates_per_ticket = associates_per_ticket
        self.hourly_wage_usd = hourly_wage_usd
        self.automation_yield = automation_yield
        self.tooling_capex_usd = tooling_capex_usd

    def calculate_metrics(self):
        """Calculates core bottleneck labor hours and financial savings."""
        bottleneck_tickets = self.annual_tickets * self.bottleneck_rate
        hours_per_ticket = self.manual_hours_per_assoc * self.associates_per_ticket
        total_bottleneck_hours = bottleneck_tickets * hours_per_ticket
        total_bottleneck_cost = total_bottleneck_hours * self.hourly_wage_usd
        
        annual_labor_savings = total_bottleneck_cost * self.automation_yield
        hours_saved_annually = total_bottleneck_hours * self.automation_yield
        fte_equivalent_saved = hours_saved_annually / 2080.0  # 2,080 working hours/year

        net_year1_benefit = annual_labor_savings - self.tooling_capex_usd
        year1_roi_pct = (net_year1_benefit / self.tooling_capex_usd) * 100.0
        payback_months = (self.tooling_capex_usd / (annual_labor_savings / 12.0))

        return {
            "annual_ticket_volume": self.annual_tickets,
            "bottleneck_tickets": round(bottleneck_tickets),
            "manual_hours_per_ticket": round(hours_per_ticket, 2),
            "total_bottleneck_person_hours": round(total_bottleneck_hours, 1),
            "total_bottleneck_cost_usd": round(total_bottleneck_cost, 2),
            "annual_labor_savings_usd": round(annual_labor_savings, 2),
            "hours_saved_annually": round(hours_saved_annually, 1),
            "fte_capacity_unlocked": round(fte_equivalent_saved, 2),
            "tooling_capex_usd": round(self.tooling_capex_usd, 2),
            "net_year1_benefit_usd": round(net_year1_benefit, 2),
            "year1_roi_percentage": round(year1_roi_pct, 1),
            "payback_period_months": round(payback_months, 1)
        }

    def generate_sensitivity_matrix(self):
        """Generates a 2D sensitivity matrix across labor wage rates and automation yields."""
        wages = [25.0, 30.0, 35.0, 40.0, 45.0, 50.0]
        yields = [0.50, 0.60, 0.70, 0.75, 0.80, 0.90]

        bottleneck_tickets = self.annual_tickets * self.bottleneck_rate
        total_hours = bottleneck_tickets * (self.manual_hours_per_assoc * self.associates_per_ticket)

        matrix = []
        for y in yields:
            row = {"Automation Yield": f"{int(y*100)}%"}
            for w in wages:
                savings = total_hours * w * y
                row[f"${int(w)}/hr"] = f"${round(savings):,}"
            matrix.append(row)

        return pd.DataFrame(matrix)

    def print_executive_summary(self):
        metrics = self.calculate_metrics()
        print("=" * 75)
        print("GUESSTIMATE FINANCIAL MODEL: BOTTLENECK COST & AUTOMATION ROI")
        print("=" * 75)
        print(f"Annual Ticket Influx Volume:             {metrics['annual_ticket_volume']:,} tickets")
        print(f"Bottleneck / SLA Breached Tickets:      {metrics['bottleneck_tickets']:,} tickets ({self.bottleneck_rate*100:.1f}%)")
        print(f"Labor Effort per Bottleneck Ticket:      {metrics['manual_hours_per_ticket']} person-hours ({self.manual_hours_per_assoc} hrs x {self.associates_per_ticket} staff)")
        print(f"Total Operational Hours Consumed:       {metrics['total_bottleneck_person_hours']:,} hrs")
        print(f"Fully Loaded Labor Rate:                 ${self.hourly_wage_usd:.2f}/hr")
        print("-" * 75)
        print(f"GROSS COST OF OPERATIONAL BOTTLENECKS:   ${metrics['total_bottleneck_cost_usd']:,}")
        print("-" * 75)
        print(f"Automation Target Yield:                 {self.automation_yield*100:.0f}% of manual verification tasks")
        print(f"Direct Annual Labor Savings:             ${metrics['annual_labor_savings_usd']:,}")
        print(f"Operational Capacity Unlocked:           {metrics['hours_saved_annually']:,} hrs ({metrics['fte_capacity_unlocked']} FTEs)")
        print(f"Implementation Tooling CapEx:            ${metrics['tooling_capex_usd']:,}")
        print(f"NET YEAR-1 FINANCIAL BENEFIT:            ${metrics['net_year1_benefit_usd']:,}")
        print(f"FIRST-YEAR RETURN ON INVESTMENT (ROI):   {metrics['year1_roi_percentage']}%")
        print(f"CAPITAL PAYBACK PERIOD:                  {metrics['payback_period_months']} months")
        print("=" * 75)

        print("\nSENSITIVITY ANALYSIS: ANNUAL LABOR SAVINGS ($)")
        print(self.generate_sensitivity_matrix().to_string(index=False))
        print("=" * 75)

def main():
    parser = argparse.ArgumentParser(description="Guesstimate Financial Modeling CLI")
    parser.add_argument("--tickets", type=int, default=10500, help="Annual ticket volume (default: 10500)")
    parser.add_argument("--rate", type=float, default=35.0, help="Loaded associate hourly wage (default: 35.0)")
    parser.add_argument("--hours", type=float, default=3.85, help="Manual hours per associate (default: 3.85)")
    parser.add_argument("--yield-pct", type=float, default=0.75, help="Automation yield percentage (default: 0.75)")
    args = parser.parse_args()

    engine = GuesstimateFinancialEngine(
        annual_tickets=args.tickets,
        hourly_wage_usd=args.rate,
        manual_hours_per_assoc=args.hours,
        automation_yield=args.yield_pct
    )
    engine.print_executive_summary()

if __name__ == "__main__":
    main()

