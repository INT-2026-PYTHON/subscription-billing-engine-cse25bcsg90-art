-- ============================================================
-- Subscription Billing Engine — Database Schema
-- ✅ COMPLETE. You will write the queries that USE this schema
--    in db/repository.py, but the table design is fixed.
-- ============================================================

PRAGMA foreign_keys = ON;

-- ----------------------------------------------------------------
-- 1. CUSTOMERS
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    name          TEXT NOT NULL,
    email         TEXT NOT NULL UNIQUE,
    country_code  TEXT NOT NULL CHECK(length(country_code) = 2),
    state_code    TEXT NOT NULL DEFAULT '',
    created_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ----------------------------------------------------------------
-- 2. PLANS
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS plans (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    name            TEXT NOT NULL,
    pricing_type    TEXT NOT NULL CHECK(pricing_type IN ('FLAT','TIERED','USAGE','FREEMIUM')),
    billing_period  TEXT NOT NULL CHECK(billing_period IN ('MONTHLY','YEARLY')),
    currency        TEXT NOT NULL CHECK(length(currency) = 3),
    config_json     TEXT NOT NULL DEFAULT '{}'
);

-- ----------------------------------------------------------------
-- 3. PLAN_TIERS (only for TIERED / USAGE-with-tiers plans)
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS plan_tiers (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    plan_id     INTEGER NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
    from_units  INTEGER NOT NULL,
    to_units    INTEGER,                       -- NULL = open-ended top tier
    unit_price  TEXT NOT NULL                  -- stored as decimal string, e.g. "0.50"
);
CREATE INDEX IF NOT EXISTS idx_plan_tiers_plan ON plan_tiers(plan_id);

-- ----------------------------------------------------------------
-- 4. DISCOUNTS
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS discounts (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    code            TEXT NOT NULL UNIQUE,
    discount_type   TEXT NOT NULL CHECK(discount_type IN ('PERCENT','FIXED','FIRST_MONTH_FREE')),
    value           TEXT NOT NULL,             -- "0.20" for 20%, or "500.00" for ₹500
    currency        TEXT,                      -- required if FIXED
    valid_until     TEXT
);

-- ----------------------------------------------------------------
-- 5. SUBSCRIPTIONS
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS subscriptions (
    id                     INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id            INTEGER NOT NULL REFERENCES customers(id),
    plan_id                INTEGER NOT NULL REFERENCES plans(id),
    status                 TEXT NOT NULL CHECK(status IN ('TRIAL','ACTIVE','PAST_DUE','CANCELLED')),
    current_period_start   TEXT NOT NULL,
    current_period_end     TEXT NOT NULL,
    trial_end              TEXT,
    discount_id            INTEGER REFERENCES discounts(id),
    past_due_since         TEXT
);
CREATE INDEX IF NOT EXISTS idx_sub_due ON subscriptions(status, current_period_end);

-- ----------------------------------------------------------------
-- 6. USAGE_RECORDS
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS usage_records (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    subscription_id INTEGER NOT NULL REFERENCES subscriptions(id),
    metric          TEXT NOT NULL,
    quantity        INTEGER NOT NULL,
    recorded_at     TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_usage_sub_time ON usage_records(subscription_id, recorded_at);

-- ----------------------------------------------------------------
-- 7. INVOICES
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS invoices (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    subscription_id   INTEGER NOT NULL REFERENCES subscriptions(id),
    period_start      TEXT NOT NULL,
    period_end        TEXT NOT NULL,
    currency          TEXT NOT NULL,
    subtotal          TEXT NOT NULL,
    discount_total    TEXT NOT NULL,
    tax_total         TEXT NOT NULL,
    total             TEXT NOT NULL,
    status            TEXT NOT NULL CHECK(status IN ('DRAFT','ISSUED','PAID','FAILED','VOID')),
    issued_at         TEXT,
    pdf_path          TEXT,
    -- IDEMPOTENCY: one invoice per (subscription, period_start)
    UNIQUE(subscription_id, period_start)
);

-- ----------------------------------------------------------------
-- 8. INVOICE_LINE_ITEMS
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS invoice_line_items (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    invoice_id   INTEGER NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    description  TEXT NOT NULL,
    amount       TEXT NOT NULL,
    kind         TEXT NOT NULL CHECK(kind IN
        ('BASE','USAGE','DISCOUNT','TAX','PRORATION_CREDIT','PRORATION_CHARGE'))
);
CREATE INDEX IF NOT EXISTS idx_lineitems_invoice ON invoice_line_items(invoice_id);

-- ----------------------------------------------------------------
-- 9. LEDGER_ENTRIES (APPEND-ONLY — your code must never UPDATE/DELETE)
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ledger_entries (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    invoice_id   INTEGER REFERENCES invoices(id),
    customer_id  INTEGER NOT NULL REFERENCES customers(id),
    amount       TEXT NOT NULL,
    currency     TEXT NOT NULL,
    direction    TEXT NOT NULL CHECK(direction IN ('DEBIT','CREDIT')),
    reason       TEXT NOT NULL,
    created_at   TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_ledger_customer ON ledger_entries(customer_id, created_at);

-- ----------------------------------------------------------------
-- 10. PAYMENT_ATTEMPTS
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payment_attempts (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    invoice_id      INTEGER NOT NULL REFERENCES invoices(id),
    attempt_no      INTEGER NOT NULL,
    status          TEXT NOT NULL CHECK(status IN ('SUCCESS','FAILED')),
    failure_reason  TEXT,
    attempted_at    TEXT NOT NULL DEFAULT (datetime('now')),
    next_retry_at   TEXT
);
CREATE INDEX IF NOT EXISTS idx_pa_invoice ON payment_attempts(invoice_id, attempt_no);
pragma foreign_keys = on;

create table if not exists customers(
    id integer primary key autoincrement,
    name text not null,
    email text not null unique,
    country_code text not null check(length(country_code)=2),
    state_code text not null default '',
    created_at text not null default(datetime('now'))
);

create table if not exists plans(
    id integer primary key autoincrement,
    name text not null,
    pricing_type text not null check(pricing_type in('flat','tiered','usage','freemium')),
    billing_period text not null check(billing_period in('monthly','yearly')),
    currency text not null check(length(currency)=3),
    config_json text not null default '{}'
);

create table if not exists plan_tiers(
    id integer primary key autoincrement,
    plan_id integer not null references plans(id) on delete cascade,
    from_units integer not null,
    to_units integer,
    unit_price text not null
);
create index if not exists idx_plan_tiers_plan on plan_tiers(plan_id);

create table if not exists discounts(
    id integer primary key autoincrement,
    code text not null unique,
    discount_type text not null check(discount_type in('percent','fixed','first_month_free')),
    value text not null,
    currency text,
    valid_until text
);

create table if not exists subscriptions(
    id integer primary key autoincrement,
    customer_id integer not null references customers(id),
    plan_id integer not null references plans(id),
    status text not null check(status in('trial','active','past_due','cancelled')),
    current_period_start text not null,
    current_period_end text not null,
    trial_end text,
    discount_id integer references discounts(id),
    past_due_since text
);
create index if not exists idx_sub_due on subscriptions(status,current_period_end);

create table if not exists usage_records(
    id integer primary key autoincrement,
    subscription_id integer not null references subscriptions(id),
    metric text not null,
    quantity integer not null,
    recorded_at text not null default(datetime('now'))
);
create index if not exists idx_usage_sub_time on usage_records(subscription_id,recorded_at);

create table if not exists invoices(
    id integer primary key autoincrement,
    subscription_id integer not null references subscriptions(id),
    period_start text not null,
    period_end text not null,
    currency text not null,
    subtotal text not null,
    discount_total text not null,
    tax_total text not null,
    total text not null,
    status text not null check(status in('draft','issued','paid','failed','void')),
    issued_at text,
    pdf_path text,
    unique(subscription_id,period_start)
);

create table if not exists invoice_line_items(
    id integer primary key autoincrement,
    invoice_id integer not null references invoices(id) on delete cascade,
    description text not null,
    amount text not null,
    kind text not null check(kind in('base','usage','discount','tax','proration_credit','proration_charge'))
);
create index if not exists idx_lineitems_invoice on invoice_line_items(invoice_id);

create table if not exists ledger_entries(
    id integer primary key autoincrement,
    invoice_id integer references invoices(id),
    customer_id integer not null references customers(id),
    amount text not null,
    currency text not null,
    direction text not null check(direction in('debit','credit')),
    reason text not null,
    created_at text not null default(datetime('now'))
);
create index if not exists idx_ledger_customer on ledger_entries(customer_id,created_at);

create table if not exists payment_attempts(
    id integer primary key autoincrement,
    invoice_id integer not null references invoices(id),
    attempt_no integer not null,
    status text not null check(status in('success','failed')),
    failure_reason text,
    attempted_at text not null default(datetime('now')),
    next_retry_at text
);
create index if not exists idx_pa_invoice on payment_attempts(invoice_id,attempt_no);
