-- Glue Catalog lowercases table names on creation, so the physical
-- Athena tables the Glue job writes are `grn`, `issue`, `pur` — not
-- GRN/PUR/ISSUE, and not the *_daily_main names the gold-layer views
-- in gold_views.sql expect. These three views bridge that gap.

CREATE OR REPLACE VIEW grn_daily_main AS
SELECT * FROM grn;

CREATE OR REPLACE VIEW issue_daily_main AS
SELECT * FROM issue;

CREATE OR REPLACE VIEW pur_order_daily_main AS
SELECT * FROM pur;
