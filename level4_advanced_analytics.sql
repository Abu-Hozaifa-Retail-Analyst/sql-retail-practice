/* ============================================================
   Level 4 - Window functions + margin analysis
   Database : sql_query_practice   (SQL Server / SSMS)
   Tables   : dbo.fact_sales, dbo.dim_product, dbo.dim_store
   Setup    : run setup.sql first

   Naming convention used in this file
     - CTE names say what the CTE holds (monthly_sales, ranked_customers)
     - Table aliases are full words (sales, product)
     - Column aliases say what they contain (previous_month_sales)
   ============================================================ */

USE sql_query_practice;
GO


/* ------------------------------------------------------------
   Challenge 1: Month-over-month sales growth with LAG()
   Q: How did total net sales change from one month to the next?
   Note: LAG() looks at the previous row. January has no previous
         month, so it returns NULL. NULLIF avoids divide-by-zero.
         The data covers one year (2025). If yours spans several
         years, group by YEAR() as well.
   ------------------------------------------------------------ */
WITH monthly_sales AS (
    SELECT MONTH(transaction_date) AS sales_month,
           SUM(net_sales)          AS net_sales
    FROM dbo.fact_sales
    GROUP BY MONTH(transaction_date)
),
sales_with_previous_month AS (
    SELECT sales_month, net_sales,
        LAG(net_sales) OVER (ORDER BY sales_month)
            AS previous_month_sales
    FROM monthly_sales
)
SELECT sales_month, net_sales,
    previous_month_sales,
    ROUND((net_sales - previous_month_sales)
        * 100.0 / NULLIF(previous_month_sales, 0), 1)
        AS mom_growth_pct
FROM sales_with_previous_month
ORDER BY sales_month;


/* Bonus: the same growth, separately for each store
   (PARTITION BY restarts LAG for every store). */
WITH monthly_store_sales AS (
    SELECT store_id,
           MONTH(transaction_date) AS sales_month,
           SUM(net_sales)          AS net_sales
    FROM dbo.fact_sales
    GROUP BY store_id, MONTH(transaction_date)
),
store_sales_with_previous_month AS (
    SELECT store_id, sales_month, net_sales,
        LAG(net_sales) OVER (
            PARTITION BY store_id
            ORDER BY sales_month
        ) AS previous_month_sales
    FROM monthly_store_sales
)
SELECT store_id, sales_month, net_sales,
    previous_month_sales,
    ROUND((net_sales - previous_month_sales)
        * 100.0 / NULLIF(previous_month_sales, 0), 1)
        AS mom_growth_pct
FROM store_sales_with_previous_month
ORDER BY store_id, sales_month;


/* ------------------------------------------------------------
   Challenge 2: Top 3 customers per store with ROW_NUMBER()
   Q: Who are the biggest spenders in every store?
   Note: customer_id is a tie-breaker, so the result is always
         the same even if two customers spent the same amount.
   ------------------------------------------------------------ */
WITH customer_sales AS (
    SELECT store_id, customer_id,
           SUM(net_sales) AS total_net_sales
    FROM dbo.fact_sales
    GROUP BY store_id, customer_id
),
ranked_customers AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY store_id
            ORDER BY total_net_sales DESC, customer_id
        ) AS customer_rank
    FROM customer_sales
)
SELECT store_id, customer_id, total_net_sales, customer_rank
FROM ranked_customers
WHERE customer_rank <= 3
ORDER BY store_id, customer_rank;


/* ------------------------------------------------------------
   Challenge 3: Profit margin per category and per product
   Q: Which categories and products keep the most of each sale?
   gross_profit     = net_sales - quantity * unit_cost
   gross_margin_pct = gross_profit / net_sales * 100
   ------------------------------------------------------------ */

-- 3a. By category
WITH sales_profit AS (
    SELECT product.category,
        sales.net_sales,
        sales.net_sales
            - sales.quantity * product.unit_cost
            AS gross_profit
    FROM dbo.fact_sales AS sales
    JOIN dbo.dim_product AS product
        ON sales.product_id = product.product_id
)
SELECT category,
    SUM(net_sales)    AS net_sales,
    SUM(gross_profit) AS gross_profit,
    ROUND(SUM(gross_profit) * 100.0
        / NULLIF(SUM(net_sales), 0), 1)
        AS gross_margin_pct
FROM sales_profit
GROUP BY category
ORDER BY gross_margin_pct DESC;

-- 3b. By product (inside its category)
WITH sales_profit AS (
    SELECT product.category,
        product.product_id,
        product.product_name,
        sales.net_sales,
        sales.net_sales
            - sales.quantity * product.unit_cost
            AS gross_profit
    FROM dbo.fact_sales AS sales
    JOIN dbo.dim_product AS product
        ON sales.product_id = product.product_id
)
SELECT category, product_name,
    SUM(net_sales)    AS net_sales,
    SUM(gross_profit) AS gross_profit,
    ROUND(SUM(gross_profit) * 100.0
        / NULLIF(SUM(net_sales), 0), 1)
        AS gross_margin_pct
FROM sales_profit
GROUP BY category, product_id, product_name
ORDER BY gross_margin_pct DESC;


/* ------------------------------------------------------------
   Challenge 4: ROW_NUMBER vs RANK vs DENSE_RANK on the same data
   Q: Rank customers by number of purchases in each store.
     row_number_rank    : 1,2,3,4  never ties (needs a tie-breaker)
     rank_with_gaps     : 1,2,2,4  ties share a rank, then a gap
     dense_rank_no_gaps : 1,2,2,3  ties share a rank, no gap
   ------------------------------------------------------------ */
WITH customer_purchases AS (
    SELECT store_id, customer_id,
           COUNT(*) AS purchases
    FROM dbo.fact_sales
    GROUP BY store_id, customer_id
)
SELECT store_id, customer_id, purchases,
    ROW_NUMBER() OVER (
        PARTITION BY store_id
        ORDER BY purchases DESC, customer_id
    ) AS row_number_rank,
    RANK() OVER (
        PARTITION BY store_id
        ORDER BY purchases DESC
    ) AS rank_with_gaps,
    DENSE_RANK() OVER (
        PARTITION BY store_id
        ORDER BY purchases DESC
    ) AS dense_rank_no_gaps
FROM customer_purchases
ORDER BY store_id, row_number_rank;
