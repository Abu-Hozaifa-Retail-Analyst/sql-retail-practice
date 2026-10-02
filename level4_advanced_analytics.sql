/* ============================================================
   Level 4 - Window functions + margin analysis
   Database : sql_query_practice   (SQL Server / SSMS)
   Tables   : dbo.fact_sales, dbo.dim_product, dbo.dim_store
   Setup    : run setup.sql first
   ============================================================ */

USE sql_query_practice;
GO


/* ------------------------------------------------------------
   Challenge 1: Month-over-month sales growth with LAG()
   Q: How did total net sales change from one month to the next?
   Note: LAG() looks at the previous row. January has no previous
         month, so it returns NULL. NULLIF avoids divide-by-zero.
   ------------------------------------------------------------ */
WITH monthly AS (
    SELECT
        YEAR(transaction_date)  AS sales_year,
        MONTH(transaction_date) AS sales_month,
        SUM(net_sales)          AS net_sales
    FROM dbo.fact_sales
    GROUP BY YEAR(transaction_date), MONTH(transaction_date)
),
with_prev AS (
    SELECT
        sales_year,
        sales_month,
        net_sales,
        LAG(net_sales) OVER (ORDER BY sales_year, sales_month) AS prev_month_sales
    FROM monthly
)
SELECT
    sales_year,
    sales_month,
    net_sales,
    prev_month_sales,
    ROUND((net_sales - prev_month_sales) * 100.0
          / NULLIF(prev_month_sales, 0), 1) AS mom_growth_pct
FROM with_prev
ORDER BY sales_year, sales_month;


/* Bonus: the same growth, but separately for each store
   (PARTITION BY restarts LAG for every store). */
WITH monthly AS (
    SELECT
        store_id,
        MONTH(transaction_date) AS sales_month,
        SUM(net_sales)          AS net_sales
    FROM dbo.fact_sales
    GROUP BY store_id, MONTH(transaction_date)
)
SELECT
    store_id,
    sales_month,
    net_sales,
    LAG(net_sales) OVER (PARTITION BY store_id ORDER BY sales_month) AS prev_month_sales,
    ROUND((net_sales - LAG(net_sales) OVER (PARTITION BY store_id ORDER BY sales_month)) * 100.0
          / NULLIF(LAG(net_sales) OVER (PARTITION BY store_id ORDER BY sales_month), 0), 1) AS mom_growth_pct
FROM monthly
ORDER BY store_id, sales_month;


/* ------------------------------------------------------------
   Challenge 2: Top 3 customers per store with ROW_NUMBER()
   Q: Who are the biggest spenders in every store?
   Note: customer_id is a tie-breaker, so the result is always
         the same even if two customers spent the same amount.
   ------------------------------------------------------------ */
WITH customer_sales AS (
    SELECT
        store_id,
        customer_id,
        SUM(net_sales) AS total_net_sales
    FROM dbo.fact_sales
    GROUP BY store_id, customer_id
),
ranked AS (
    SELECT
        store_id,
        customer_id,
        total_net_sales,
        ROW_NUMBER() OVER (
            PARTITION BY store_id
            ORDER BY total_net_sales DESC, customer_id
        ) AS customer_rank
    FROM customer_sales
)
SELECT store_id, customer_id, total_net_sales, customer_rank
FROM ranked
WHERE customer_rank <= 3
ORDER BY store_id, customer_rank;


/* ------------------------------------------------------------
   Challenge 3: Profit margin per category and per product
   Q: Which categories and products keep the most of each sale?
   gross_profit = net_sales - quantity * unit_cost
   margin %     = gross_profit / net_sales * 100
   ------------------------------------------------------------ */

-- 3a. By category
SELECT
    p.category,
    SUM(s.net_sales) AS net_sales,
    SUM(s.net_sales - s.quantity * p.unit_cost) AS gross_profit,
    ROUND(SUM(s.net_sales - s.quantity * p.unit_cost) * 100.0
          / NULLIF(SUM(s.net_sales), 0), 1) AS gross_margin_pct
FROM dbo.fact_sales AS s
INNER JOIN dbo.dim_product AS p
    ON s.product_id = p.product_id
GROUP BY p.category
ORDER BY gross_margin_pct DESC;

-- 3b. By product (inside its category)
SELECT
    p.category,
    p.product_name,
    SUM(s.net_sales) AS net_sales,
    SUM(s.net_sales - s.quantity * p.unit_cost) AS gross_profit,
    ROUND(SUM(s.net_sales - s.quantity * p.unit_cost) * 100.0
          / NULLIF(SUM(s.net_sales), 0), 1) AS gross_margin_pct
FROM dbo.fact_sales AS s
INNER JOIN dbo.dim_product AS p
    ON s.product_id = p.product_id
GROUP BY p.category, p.product_id, p.product_name
ORDER BY gross_margin_pct DESC;


/* ------------------------------------------------------------
   Challenge 4: ROW_NUMBER vs RANK vs DENSE_RANK on the same data
   Q: Rank customers by number of purchases in each store.
     ROW_NUMBER : 1,2,3,4  never ties (needs a tie-breaker)
     RANK       : 1,2,2,4  ties share a rank, then a gap
     DENSE_RANK : 1,2,2,3  ties share a rank, no gap
   ------------------------------------------------------------ */
WITH purchases AS (
    SELECT
        store_id,
        customer_id,
        COUNT(*) AS purchases
    FROM dbo.fact_sales
    GROUP BY store_id, customer_id
)
SELECT
    store_id,
    customer_id,
    purchases,
    ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY purchases DESC, customer_id) AS row_num,
    RANK()       OVER (PARTITION BY store_id ORDER BY purchases DESC) AS rnk,
    DENSE_RANK() OVER (PARTITION BY store_id ORDER BY purchases DESC) AS dense_rnk
FROM purchases
ORDER BY store_id, row_num;
