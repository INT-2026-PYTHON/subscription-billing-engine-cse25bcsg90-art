"""
DunningProcess — finite state machine for failed-payment retries.

States:
    PENDING       (initial)  →  RETRYING  on first failure
    RETRYING      ──→ SUCCEEDED    when a retry succeeds
                  ──→ FAILED_FINAL after 3 total failures
    SUCCEEDED     (terminal)
    FAILED_FINAL  (terminal — also flips subscription to PAST_DUE)

Retry schedule:
    attempt 2 scheduled at  now + 1 day
    attempt 3 scheduled at  now + 3 days
    (no attempt 4 — after the 3rd failure we mark FAILED_FINAL)

After the subscription has been PAST_DUE for 7 days with no recovery,
the BillingCycle.run (Day 2 work) may flip it to CANCELLED — that
transition does NOT live in this file.
"""
from enum import Enum, auto

class State(Enum):
    PENDING = auto()
    RETRYING = auto()
    SUCCEEDED = auto()
    FAILED_FINAL = auto()

class DunningProcess:
    def __init__(self):
        self.state = State.PENDING
        self.failures = 0

    def fail(self):
        if self.state == State.PENDING:
            self.state = State.RETRYING
            self.failures = 1
        elif self.state == State.RETRYING:
            self.failures += 1
            if self.failures >= 3:
                self.state = State.FAILED_FINAL

    def succeed(self):
        if self.state == State.RETRYING:
            self.state = State.SUCCEEDED

