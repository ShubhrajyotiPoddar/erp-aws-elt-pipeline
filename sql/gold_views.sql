-- Gold-layer business views, built on top of grn_daily_main /
-- issue_daily_main / pur_order_daily_main (see compatibility_views.sql).
-- Run compatibility_views.sql first.

CREATE OR REPLACE VIEW public.cost_master_main
AS WITH combined_cost_projects AS (
         SELECT pur_order_daily_main.cost_project,
            pur_order_daily_main.cost_project_name
           FROM pur_order_daily_main
          WHERE pur_order_daily_main.cost_project IS NOT NULL
        UNION
         SELECT grn_daily_main.cost_project,
            grn_daily_main.cost_project_name
           FROM grn_daily_main
          WHERE grn_daily_main.cost_project IS NOT NULL
        UNION
         SELECT issue_daily_main.cost_centre_code AS cost_project,
            issue_daily_main.cost_name AS cost_project_name
           FROM issue_daily_main
          WHERE issue_daily_main.cost_centre_code IS NOT NULL
        ), ranked_cost_projects AS (
         SELECT combined_cost_projects.cost_project,
            combined_cost_projects.cost_project_name,
            row_number() OVER (PARTITION BY combined_cost_projects.cost_project ORDER BY (length(combined_cost_projects.cost_project_name::text)) DESC) AS rn
           FROM combined_cost_projects
        )
 SELECT cost_project AS cost_code,
    cost_project_name
   FROM ranked_cost_projects
  WHERE rn = 1
  ORDER BY cost_project;

CREATE OR REPLACE VIEW public.department_master_main
AS WITH combined_departments AS (
         SELECT pur_order_daily_main.department,
            pur_order_daily_main.department_name
           FROM pur_order_daily_main
          WHERE pur_order_daily_main.department IS NOT NULL
        UNION
         SELECT grn_daily_main.department,
            grn_daily_main.department_name
           FROM grn_daily_main
          WHERE grn_daily_main.department IS NOT NULL
        UNION
         SELECT issue_daily_main.department_code AS department,
            issue_daily_main.department_name
           FROM issue_daily_main
          WHERE issue_daily_main.department_code IS NOT NULL
        ), ranked_departments AS (
         SELECT combined_departments.department,
            combined_departments.department_name,
            row_number() OVER (PARTITION BY combined_departments.department ORDER BY (length(combined_departments.department_name::text)) DESC) AS rn
           FROM combined_departments
        )
 SELECT department AS department_code,
    department_name
   FROM ranked_departments
  WHERE rn = 1
  ORDER BY department;

CREATE OR REPLACE VIEW public.item_master_main
AS WITH combined_data AS (
         SELECT issue_daily_main.item_category_code,
            issue_daily_main.item_category_name,
            issue_daily_main.item_code,
            issue_daily_main.item_name
           FROM issue_daily_main
          WHERE issue_daily_main.item_category_code IS NOT NULL AND issue_daily_main.item_code IS NOT NULL
        UNION ALL
         SELECT pur_order_daily_main.item_category_code,
            pur_order_daily_main.item_category_name,
            pur_order_daily_main.item_code,
            pur_order_daily_main.item_name
           FROM pur_order_daily_main
          WHERE pur_order_daily_main.item_category_code IS NOT NULL AND pur_order_daily_main.item_code IS NOT NULL
        UNION ALL
         SELECT grn_daily_main.item_ctag_code,
            grn_daily_main.item_ctag_name,
            grn_daily_main.item_code,
            grn_daily_main.item_name
           FROM grn_daily_main
          WHERE grn_daily_main.item_ctag_code IS NOT NULL AND grn_daily_main.item_code IS NOT NULL
        ), ranked_data AS (
         SELECT combined_data.item_category_code,
            combined_data.item_code,
            combined_data.item_category_name,
            combined_data.item_name,
            row_number() OVER (PARTITION BY combined_data.item_category_code, combined_data.item_code ORDER BY (length(combined_data.item_category_name::text)) DESC, (length(combined_data.item_name::text)) DESC) AS rn
           FROM combined_data
        )
 SELECT item_category_code,
    item_category_name,
    item_code,
    item_name
   FROM ranked_data
  WHERE rn = 1
  ORDER BY item_category_code, item_code;

CREATE OR REPLACE VIEW public.pur_grn
AS SELECT p.order_date AS pur_order_date,
    p.item_category_code,
    p.item_code AS pur_item_code,
    p.order_number AS pur_order_number,
    p.supplier_code,
    p.supplier_name,
    p.department,
    p.department_name,
    p.cost_project,
    p.cost_project_name,
    p.rate,
        CASE
            WHEN row_number() OVER (PARTITION BY p.order_number, p.item_code ORDER BY g.grn_date) = 1 THEN p.order_value
            ELSE '0'::character varying
        END AS pur_order_value,
    g.grn_date,
    g.grn_number,
    g.net_amount AS grn_net_amount
   FROM pur_order_daily_main p
     LEFT JOIN grn_daily_main g ON TRIM(BOTH FROM p.order_number::text) = TRIM(BOTH FROM g.purchase_order_number::text) AND TRIM(BOTH FROM p.item_code::text) = TRIM(BOTH FROM g.item_code::text);

CREATE OR REPLACE VIEW public.supplier_master_main
AS WITH combined_suppliers AS (
         SELECT pur_order_daily_main.supplier_code,
            pur_order_daily_main.supplier_name
           FROM pur_order_daily_main
          WHERE pur_order_daily_main.supplier_code IS NOT NULL
        UNION
         SELECT grn_daily_main.supplier_code,
            grn_daily_main.supplier_name
           FROM grn_daily_main
          WHERE grn_daily_main.supplier_code IS NOT NULL
        ), ranked_suppliers AS (
         SELECT combined_suppliers.supplier_code,
            combined_suppliers.supplier_name,
            row_number() OVER (PARTITION BY combined_suppliers.supplier_code ORDER BY (length(combined_suppliers.supplier_name::text)) DESC) AS rn
           FROM combined_suppliers
        )
 SELECT supplier_code,
    supplier_name
   FROM ranked_suppliers
  WHERE rn = 1
  ORDER BY supplier_code;
