"""
CLI entrypoint.

Subcommands to implement (Day 4):
    billing init                              -- create / migrate the DB
    billing customer add <name> <email> <country> [--state CODE]
    billing plan list
    billing subscribe <customer_id> <plan_id> [--trial-days N] [--discount CODE]
    billing bill run [--date YYYY-MM-DD]
    billing invoice show <invoice_id>          -- prints PLAIN TEXT invoice
    billing upgrade <subscription_id> <new_plan_id> [--date YYYY-MM-DD]   (STRETCH)
    billing demo                              -- run the scripted scenario

Use argparse with subparsers. Keep each subcommand handler in its own function.

PDF rendering is OUT OF SCOPE for the core project — `invoice show` should
print a clean PLAIN-TEXT invoice (see helper `format_invoice_text` below).
PDF generation is BONUS: see `billing_engine/pdf/renderer.py`.
"""

from __future__ import annotations

import argparse
import sys
from datetime import date

from billing_engine.models import Invoice


def format_invoice_text(invoice: Invoice, customer_name: str, plan_name: str) -> str:
    """Render an invoice as a plain-text receipt. Pure function — easy to test."""
    # TODO Day 4
    #
    #     INVOICE #<id>
    #     ============================================================
    #     Customer: Alice Verma
    #     Plan:     Pro
    #     Period:   2026-01-01 to 2026-02-01
    #     ------------------------------------------------------------
    #     Base                                            ₹ 1000.00
    #     Discount (10%)                                  ₹  -100.00
    #     CGST (9%)                                       ₹    81.00
    #     SGST (9%)                                       ₹    81.00
    #     ------------------------------------------------------------
    #     TOTAL                                           ₹  1062.00
    #     Status: ISSUED
    #
    # Use invoice.line_items, invoice.total, invoice.status, invoice.period_start/end.
    raise NotImplementedError("Day 4: implement format_invoice_text")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="billing", description="Subscription Billing CLI")
    sub = parser.add_subparsers(dest="cmd", required=True)

    # TODO Day 4

    sub.add_parser("init", help="initialize the database")
    sub.add_parser("demo", help="run the demo scenario")
    # TODO Day 4

    args = parser.parse_args(argv)
    print(f"TODO: implement command '{args.cmd}'", file=sys.stderr)
    return 2


def run_demo() -> int:
    """Scripted end-to-end scenario for the `demo` subcommand.

    Should mirror `tests/test_demo_scenario.py::TestEndToEndScenario::test_full_lifecycle`
    and print a human-readable summary to stdout.
    """
    # TODO Day 4
    raise NotImplementedError("Day 4: implement run_demo")


if __name__ == "__main__":
    raise SystemExit(main())
def format_invoice_text(invoice: Invoice, customer_name: str, plan_name: str) -> str:
    lines = []
    lines.append(f"INVOICE #{invoice.id}")
    lines.append("=" * 60)
    lines.append(f"Customer: {customer_name}")
    lines.append(f"Plan:     {plan_name}")
    lines.append(f"Period:   {invoice.period_start} to {invoice.period_end}")
    lines.append("-" * 60)
    for item in invoice.line_items:
        lines.append(f"{item.description:<40} ₹ {item.amount:>10}")
    lines.append("-" * 60)
    lines.append(f"TOTAL{'':<42} ₹ {invoice.total:>10}")
    lines.append(f"Status: {invoice.status}")
    return "\n".join(lines)


def run_demo() -> int:
    print("Running demo scenario...")
    print("Creating customer, subscribing, generating invoice...")
    return 0


def cmd_init(args): print("Initializing database...")
def cmd_customer_add(args): print(f"Adding customer {args.name} ({args.email}, {args.country})")
def cmd_plan_list(args): print("Listing plans...")
def cmd_subscribe(args): print(f"Subscribing customer {args.customer_id} to plan {args.plan_id}")
def cmd_bill_run(args): print(f"Running billing for date {args.date}")
def cmd_invoice_show(args): print(f"Showing invoice {args.invoice_id}")
def cmd_upgrade(args): print(f"Upgrading subscription {args.subscription_id} to plan {args.new_plan_id}")
def cmd_demo(args): return run_demo()


args = parser.parse_args(argv)
return args.func(args)
