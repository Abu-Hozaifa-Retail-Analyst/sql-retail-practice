/* ============================================================
   Level 3 - JOIN + KPI + Validation
   Database : sql_query_practice   (SQL Server / SSMS)
   Tables   : dbo.fact_sales -> dbo.dim_product -> dbo.dim_store
   Setup    : run setup.sql first
   ============================================================

   Business problem
   The Retail Manager says Store S02 generated strong sales, but
   wants to know whether its performance is still strong once
   profitability is considered.

   KPIs per store
     Net Sales       = SUM(net_sales)
     Gross Profit    = SUM(net_sales - quantity * unit_cost)
     Gross Margin %  = Gross Profit / Net Sales * 100

   Design notes
     - unit_cost lives in dim_product, store_name in dim_store,
       so both dimensions are joined to fact_sales.
     - NULLIF(..., 0) prevents a divide-by-zero error.
     - 100.0 (not 100) avoids integer division.
   ============================================================ */

USE sql_query_practice;
GO

-- 1. Store profitability
SELECT
    st.store_id,
    st.store_name,
    SUM(s.net_sales) AS net_sales,
    SUM(s.net_sales - s.quantity * p.unit_cost) AS gross_profit,
    ROUND(
        SUM(s.net_sales - s.quantity * p.unit_cost) * 100.0
        / NULLIF(SUM(s.net_sales), 0)
    , 2) AS gross_margin_pct
FROM dbo.fact_sales AS s
INNER JOIN dbo.dim_store AS st
    ON s.store_id = st.store_id
INNER JOIN dbo.dim_product AS p
    ON s.product_id = p.product_id
GROUP BY
    st.store_id,
    st.store_name
ORDER BY gross_margin_pct DESC;


-- 2. Validation: joins must not drop or duplicate rows.
--    Both numbers should be identical (120,970 on the sample data).
SELECT SUM(net_sales) AS raw_fact_total
FROM dbo.fact_sales;

SELECT SUM(s.net_sales) AS total_after_joins
FROM dbo.fact_sales AS s
INNER JOIN dbo.dim_store AS st
    ON s.store_id = st.store_id
INNER JOIN dbo.dim_product AS p
    ON s.product_id = p.product_id;
