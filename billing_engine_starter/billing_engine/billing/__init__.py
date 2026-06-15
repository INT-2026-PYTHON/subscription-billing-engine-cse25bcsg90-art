"""Billing workflow — pipeline, cycle, dunning, proration."""
from .pipeline import build_invoice
from .cycle import BillingCycle
from .dunning import DunningProcess, DunningState
from .proration import compute_proration

__all__ = [
    "build_invoice",
    "BillingCycle",
    "DunningProcess",
    "DunningState",
    "compute_proration",
]
def build_invoice(customer, amount):
    return {"customer": customer, "amount": amount, "status": "unpaid"}

class BillingCycle:
    def __init__(self, start_date, end_date):
        self.start_date = start_date
        self.end_date = end_date

class DunningState:
    PENDING = "pending"
    SENT = "sent"
    PAID = "paid"

class DunningProcess:
    def __init__(self, invoice):
        self.invoice = invoice
        self.state = DunningState.PENDING
    def send_reminder(self):
        self.state = DunningState.SENT
        return f"Reminder sent to {self.invoice['customer']}"
    def mark_paid(self):
        self.state = DunningState.PAID
        self.invoice["status"] = "paid"

def compute_proration(full_amount, used_days, total_days):
    return (full_amount / total_days) * used_days

from pipeline import build_invoice
from cycle import BillingCycle
from dunning import DunningProcess
from proration import compute_proration

invoice = build_invoice("Samir", 1000)
cycle = BillingCycle("2026-06-01", "2026-06-30")
prorated = compute_proration(1000, 15, 30)
dp = DunningProcess(invoice)
print(dp.send_reminder())
dp.mark_paid()
print(invoice)
