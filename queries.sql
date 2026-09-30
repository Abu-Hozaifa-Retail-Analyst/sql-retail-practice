/* ============================================================
   Retail SQL Practice - 5 business questions, 5 SQL skills
   Database : sql_query_practice   (SQL Server / SSMS)
   Tables   : dbo.fact_sales, dbo.dim_product, dbo.dim_store
   Setup    : run setup.sql first
   ============================================================ */

USE sql_query_practice;
GO


/* ------------------------------------------------------------
   1. WHERE + date filtering
   Q: Show store S01's transactions from Jan 1 to Jan 10, 2025.
   Note: '< Jan 11' keeps ALL of Jan 10, even if the column has a
         time part. BETWEEN ... '2025-01-10' would stop at midnight.
   ------------------------------------------------------------ */
SELECT
    transaction_id,
    transaction_date,
    customer_id,
    product_id,
    quantity,
    net_sales
FROM dbo.fact_sales
WHERE store_id = 'S01'
  AND transaction_date >= '2025-01-01'
  AND transaction_date <  '2025-01-11'
ORDER BY transaction_date, transaction_id;


/* ------------------------------------------------------------
   2. GROUP BY + aggregates
   Q: How much did each store sell?
   ------------------------------------------------------------ */
SELECT
    store_id,
    SUM(net_sales)        AS total_net_sales,
    SUM(quantity)         AS total_units_sold,
    COUNT(transaction_id) AS number_of_transactions
FROM dbo.fact_sales
GROUP BY store_id
ORDER BY total_net_sales DESC;


/* ------------------------------------------------------------
   3. JOIN (fact table + dimension table)
   Q: Which product categories perform best?
   ------------------------------------------------------------ */
SELECT
    p.category,
    SUM(s.net_sales) AS total_net_sales,
    SUM(s.quantity)  AS total_units_sold
FROM dbo.fact_sales s
JOIN dbo.dim_product p
    ON s.product_id = p.product_id
GROUP BY p.category
ORDER BY total_net_sales DESC;


/* ------------------------------------------------------------
   4. CASE statement
   Q: Which sales are low, medium or high value?
        < 200        -> Low Value
        200 - 499.99 -> Medium Value
        >= 500       -> High Value
   Note: no GROUP BY needed (nothing is aggregated), and
         '< 500' leaves no gap for values like 499.995.
   ------------------------------------------------------------ */
SELECT
    transaction_id,
    net_sales,
    CASE
        WHEN net_sales < 200 THEN 'Low Value'
        WHEN net_sales < 500 THEN 'Medium Value'
        ELSE 'High Value'
    END AS sales_band
FROM dbo.fact_sales
ORDER BY transaction_id;


/* ------------------------------------------------------------
   5. Window function (RANK) + CTE
   Q: What are the best-selling products in each category?
   Step 1 (CTE)   : total net sales per product
   Step 2 (RANK)  : rank products inside each category
   ------------------------------------------------------------ */
WITH product_sales AS (
    SELECT
        p.category,
        p.product_id,
        p.product_name,
        SUM(s.net_sales) AS total_net_sales
    FROM dbo.fact_sales s
    JOIN dbo.dim_product p
        ON s.product_id = p.product_id
    GROUP BY
        p.category,
        p.product_id,
        p.product_name
)
SELECT
    category,
    product_id,
    product_name,
    total_net_sales,
    RANK() OVER (
        PARTITION BY category
        ORDER BY total_net_sales DESC
    ) AS sales_rank
FROM product_sales
ORDER BY category, sales_rank;
