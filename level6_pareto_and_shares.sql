/* ============================================================
   Level 6 - Pareto, customer cohorts, weekdays and shares
   Database : sql_query_practice   (SQL Server / SSMS)
   Tables   : dbo.fact_sales, dbo.dim_product, dbo.dim_store
   Setup    : run setup.sql first

   Naming convention: CTE names say what they hold, table aliases
   are full words (sales, product), column aliases say what they
   contain.
   ============================================================ */

USE sql_query_practice;
GO


/* ------------------------------------------------------------
   Challenge 1: Pareto (80/20) - which products make up 80% of sales?
   Rule: a product is in the "Core 80%" if the sales BEFORE it were
         still under 80% of the total. This includes the product that
         crosses the 80% line.
   ------------------------------------------------------------ */
WITH product_sales AS (
  SELECT product.product_name,
         SUM(sales.net_sales) AS net_sales
  FROM dbo.fact_sales AS sales
  JOIN dbo.dim_product AS product
    ON sales.product_id = product.product_id
  GROUP BY product.product_name
),
cumulative_sales AS (
  SELECT product_name, net_sales,
    SUM(net_sales) OVER (
      ORDER BY net_sales DESC, product_name
      ROWS UNBOUNDED PRECEDING) AS running_sales,
    SUM(net_sales) OVER () AS total_sales
  FROM product_sales
)
SELECT product_name, net_sales,
  ROUND(running_sales * 100.0 / total_sales, 1)
    AS cumulative_pct,
  CASE WHEN (running_sales - net_sales) * 100.0
         / total_sales < 80
    THEN 'Core 80%' ELSE 'Tail' END AS pareto_group
FROM cumulative_sales
ORDER BY net_sales DESC, product_name;


/* ------------------------------------------------------------
   Challenge 2: New vs returning customers each month
   Rule: a customer is NEW in the month of their first purchase,
         and RETURNING in every later month.
   Note: the data starts in January, so every January customer
         counts as new by definition.
   ------------------------------------------------------------ */
WITH first_purchases AS (
  SELECT customer_id,
         MIN(MONTH(transaction_date)) AS first_purchase_month
  FROM dbo.fact_sales
  GROUP BY customer_id
),
monthly_customers AS (
  SELECT DISTINCT customer_id,
         MONTH(transaction_date) AS sales_month
  FROM dbo.fact_sales
)
SELECT monthly.sales_month,
  COUNT(*) AS active_customers,
  SUM(CASE WHEN monthly.sales_month
      = first_purchase.first_purchase_month
      THEN 1 ELSE 0 END) AS new_customers,
  SUM(CASE WHEN monthly.sales_month
      > first_purchase.first_purchase_month
      THEN 1 ELSE 0 END) AS returning_customers
FROM monthly_customers AS monthly
JOIN first_purchases AS first_purchase
  ON monthly.customer_id = first_purchase.customer_id
GROUP BY monthly.sales_month
ORDER BY monthly.sales_month;


/* ------------------------------------------------------------
   Challenge 3: Best and worst weekday per store
   Q: On which weekday does each store sell the most and the least?
   Notes:
     - DATENAME(weekday, ...) returns the day name in the session
       language (English by default).
     - Totals are fair only if every weekday occurs equally often.
       In Jan 1 - Mar 31, 2025 Tuesday occurs 12 times and the other
       days 13 times, so Tuesday starts with a small disadvantage.
   ------------------------------------------------------------ */
WITH weekday_sales AS (
  SELECT store_id,
         DATENAME(weekday, transaction_date) AS weekday_name,
         SUM(net_sales) AS net_sales
  FROM dbo.fact_sales
  GROUP BY store_id, DATENAME(weekday, transaction_date)
),
ranked_weekdays AS (
  SELECT *,
    RANK() OVER (PARTITION BY store_id
      ORDER BY net_sales DESC) AS best_rank,
    RANK() OVER (PARTITION BY store_id
      ORDER BY net_sales ASC) AS worst_rank
  FROM weekday_sales
)
SELECT store_id, weekday_name, net_sales,
  CASE WHEN best_rank = 1 THEN 'Best'
       ELSE 'Worst' END AS day_type
FROM ranked_weekdays
WHERE best_rank = 1 OR worst_rank = 1
ORDER BY store_id, best_rank;


/* ------------------------------------------------------------
   Challenge 4: Each store's share of company sales, per category
   Q: How is each category's sales split between the stores?
   Note: SUM() OVER (PARTITION BY category) is the category total,
         so the shares inside one category add up to 100.
   ------------------------------------------------------------ */
WITH store_category_sales AS (
  SELECT sales.store_id, product.category,
         SUM(sales.net_sales) AS net_sales
  FROM dbo.fact_sales AS sales
  JOIN dbo.dim_product AS product
    ON sales.product_id = product.product_id
  GROUP BY sales.store_id, product.category
),
category_shares AS (
  SELECT store_id, category, net_sales,
    ROUND(net_sales * 100.0
      / SUM(net_sales) OVER (PARTITION BY category), 1)
      AS category_share_pct,
    RANK() OVER (PARTITION BY category
      ORDER BY net_sales DESC) AS store_rank
  FROM store_category_sales
)
SELECT category, store_id, net_sales,
  category_share_pct, store_rank
FROM category_shares
ORDER BY category, store_rank;
