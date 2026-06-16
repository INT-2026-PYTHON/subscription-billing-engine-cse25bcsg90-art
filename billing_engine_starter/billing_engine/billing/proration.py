"""
Proration — Day 4 stretch.

Mid-cycle plan change: customer is on Plan A from period_start to period_end,
but on `switch_date` they upgrade (or downgrade) to Plan B.

Day-count proration:
    total_days     = (period_end - period_start).days
    used_days      = (switch_date - period_start).days
    remaining_days = total_days - used_days

    credit = old_price * (remaining_days / total_days)
    charge = new_price * (remaining_days / total_days)

Tax MUST be recalculated on BOTH legs (reverse-tax on the credit,
fresh tax on the new charge). Tax is NOT prorated linearly — the tax
on a proration credit/charge is just `tax_calc.apply(credit_or_charge)`.

The two legs are returned as TAX-INCLUSIVE Money values for the
PRORATION_CREDIT (negative) and PRORATION_CHARGE (positive) line items.
"""
from datetime import date

class Money:
    def __init__(self, amount):
        self.amount = amount

    def __neg__(self):
        return Money(-self.amount)


def compute_proration(old_price, new_price, period_start, period_end, switch_date, tax_calc):

    total_days = (period_end - period_start).days

    used_days = (switch_date - period_start).days

    remaining_days = total_days - used_days

    credit = old_price * (remaining_days / total_days)

    charge = new_price * (remaining_days / total_days)

    credit_with_tax = -tax_calc.apply(credit)

    charge_with_tax = tax_calc.apply(charge)

    return credit_with_tax, charge_with_tax

