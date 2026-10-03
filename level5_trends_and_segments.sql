/* ============================================================
   Level 5 - Trends, segments and gaps
   Database : sql_query_practice   (SQL Server / SSMS)
   Tables   : dbo.fact_sales, dbo.dim_product, dbo.dim_store
   Setup    : run setup.sql first

   Naming convention: CTE names say what they hold, table aliases
   are full words (sales, product, store), column aliases say what
   they contain.
   ============================================================ */

USE sql_query_practice;
GO


/* ------------------------------------------------------------
   Challenge 1: Running total and 7-day moving average
   Q: How do daily sales build up, and what is the recent trend?
   Notes:
     - ROWS BETWEEN 6 PRECEDING AND CURRENT ROW = 7 rows (7 days
       here, because every day in the data has sales).
     - net_sales * 1.0 forces decimal math. AVG() of an INT column
       returns an INT in SQL Server and would cut off decimals.
     - The first 6 days average over fewer than 7 days.
   ------------------------------------------------------------ */
WITH daily_sales AS (
    SELECT transaction_date,
           SUM(net_sales) AS net_sales
    FROM dbo.fact_sales
    GROUP BY transaction_date
)
SELECT transaction_date, net_sales,
    SUM(net_sales) OVER (
        ORDER BY transaction_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_sales,
    ROUND(AVG(net_sales * 1.0) OVER (
        ORDER BY transaction_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 1) AS moving_avg_7_days
FROM daily_sales
ORDER BY transaction_date;


/* ------------------------------------------------------------
   Challenge 2: Loyal vs occasional customers
   Q: Who shops every month, and how much more do they spend?
   Rule: active in all 3 months (Jan, Feb, Mar) = Loyal,
         otherwise = Occasional.
   ------------------------------------------------------------ */
WITH customer_months AS (
  SELECT customer_id,
    COUNT(DISTINCT MONTH(transaction_date))
      AS active_months,
    SUM(net_sales) AS total_net_sales
  FROM dbo.fact_sales
  GROUP BY customer_id
),
customer_segments AS (
  SELECT *, CASE WHEN active_months = 3
    THEN 'Loyal' ELSE 'Occasional'
    END AS customer_type
  FROM customer_months
)
SELECT customer_type,
  COUNT(*) AS customers,
  SUM(total_net_sales) AS net_sales,
  ROUND(AVG(total_net_sales * 1.0), 1)
    AS avg_net_sales_per_customer
FROM customer_segments
GROUP BY customer_type
ORDER BY customers DESC;


/* ------------------------------------------------------------
   Challenge 3: Store and product combinations that never sold
   Q: Which products has each store never sold?
   Idea: CROSS JOIN builds every possible store + product pair,
         LEFT JOIN attaches the sales that exist, and
         "sales.transaction_id IS NULL" keeps the pairs with none.
   ------------------------------------------------------------ */
SELECT store.store_id,
       store.store_name,
       product.product_id,
       product.product_name
FROM dbo.dim_store AS store
CROSS JOIN dbo.dim_product AS product
LEFT JOIN dbo.fact_sales AS sales
    ON sales.store_id = store.store_id
   AND sales.product_id = product.product_id
WHERE sales.transaction_id IS NULL
ORDER BY store.store_id, product.product_id;


/* ------------------------------------------------------------
   Challenge 4: Which products surged from February to March?
   Q: Which products grew the most, in percent?
   Note: products with no February sales give NULL growth
         (NULLIF avoids divide-by-zero) and sort last.
   ------------------------------------------------------------ */
WITH product_february_vs_march AS (
  SELECT product_id,
    SUM(CASE WHEN MONTH(transaction_date) = 2
      THEN net_sales ELSE 0 END)
      AS february_sales,
    SUM(CASE WHEN MONTH(transaction_date) = 3
      THEN net_sales ELSE 0 END)
      AS march_sales
  FROM dbo.fact_sales
  GROUP BY product_id
)
SELECT product.product_name,
  february_sales, march_sales,
  ROUND((march_sales - february_sales) * 100.0
    / NULLIF(february_sales, 0), 1) AS growth_pct
FROM product_february_vs_march AS comparison
JOIN dbo.dim_product AS product
  ON comparison.product_id = product.product_id
ORDER BY growth_pct DESC;
