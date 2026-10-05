# Retail SQL Practice (SQL Server)

Real-world retail questions, real SQL skills. Levels 1-2 cover five core skills, Level 3 adds a profitability exercise with JOINs, KPIs and validation, Level 4 adds window functions and margin analysis, Level 5 adds trends, customer segments and sales gaps, and Level 6 adds Pareto analysis, customer cohorts, weekday patterns and store shares. Each query answers a question a Sales, Store or Category Manager might ask.

> The dataset is **synthetic** (made up for practice). No real company data is used.

## What's inside

| File | Purpose |
|---|---|
| `setup.sql` | Creates the database, tables and all sample data (run this first) |
| `queries.sql` | The 5 solved queries (Levels 1-2) with the business question above each one |
| `level3_store_profitability.sql` | Level 3 exercise: store profitability (JOIN + KPIs + validation) |
| `level4_advanced_analytics.sql` | Level 4 exercises: LAG, ROW_NUMBER, margin analysis, RANK vs DENSE_RANK |
| `level5_trends_and_segments.sql` | Level 5 exercises: moving average, customer segments, never-sold gaps, month-to-month surge |
| `level6_pareto_and_shares.sql` | Level 6 exercises: Pareto 80/20, new vs returning customers, best/worst weekday, store shares |
| `fact_sales.csv`, `dim_product.csv`, `dim_store.csv` | The same data as CSV files |

## The 5 questions

| # | Business question | SQL skill |
|---|---|---|
| 1 | Show store S01's transactions from Jan 1 to Jan 10, 2025 | `WHERE` + date filtering |
| 2 | How much did each store sell? | `GROUP BY`, `SUM`, `COUNT` |
| 3 | Which product categories perform best? | `JOIN` (fact + dimension) |
| 4 | Which sales are low, medium or high value? | `CASE` |
| 5 | What are the best-selling products in each category? | `RANK() OVER (PARTITION BY ...)` + CTE |

## Dataset

A small star schema: one fact table and two dimension tables.

```mermaid
erDiagram
    dim_store   ||--o{ fact_sales : "store_id"
    dim_product ||--o{ fact_sales : "product_id"
    fact_sales {
        int transaction_id PK
        date transaction_date
        varchar store_id FK
        varchar customer_id
        varchar product_id FK
        int quantity
        int unit_price
        int discount
        int net_sales
    }
    dim_product {
        varchar product_id PK
        varchar product_name
        varchar category
        int unit_cost
    }
    dim_store {
        varchar store_id PK
        varchar store_name
        varchar city
        varchar store_type
    }
```

- **508 transactions** from Jan 1 to Mar 31, 2025
- **16 products** in 5 categories, **6 stores** in 4 cities, 60 customers
- `net_sales = quantity * unit_price - discount` (the discount is a flat amount)

## How to run it

1. Open **SQL Server Management Studio (SSMS)** and connect to your server.
2. Open `setup.sql` and click **Execute**. The last query should return `16 | 6 | 508`.
3. Open `queries.sql` and run each query one at a time (highlight it, then press **F5**).
4. For Levels 3 to 6, open the matching `levelN_*.sql` file (for example `level6_pareto_and_shares.sql`) and run each query the same way.

`setup.sql` is safe to re-run: it drops and recreates the three tables.

## Sample results

**Query 2: net sales by store**

| store_id | total_net_sales | total_units_sold | number_of_transactions |
|---|---|---|---|
| S02 | 31,047 | 483 | 114 |
| S04 | 26,967 | 474 | 109 |
| S01 | 21,670 | 435 | 103 |
| S03 | 18,145 | 355 | 84 |
| S06 | 11,583 | 196 | 46 |
| S05 | 11,558 | 224 | 52 |

**Query 5: best sellers per category (first rows)**

| category | product_name | total_net_sales | sales_rank |
|---|---|---|---|
| Beverages | Mineral Water Pack | 5,769 | 1 |
| Beverages | Orange Juice | 2,029 | 2 |
| Electronics | Headphones | 10,923 | 1 |
| Electronics | Electric Kettle | 7,547 | 2 |
| Grocery | Dates | 15,110 | 1 |
| Grocery | Basmati Rice | 13,550 | 2 |

## Level 3: Store profitability (JOIN + KPI + Validation)

**Business problem:** the Retail Manager says Store S02 sells a lot, but wants to know whether it is still strong after considering profitability.

**Tables combined:** `fact_sales` -> `dim_product` (for `unit_cost`) -> `dim_store` (for `store_name`)

**KPIs per store**

| KPI | Formula |
|---|---|
| Net Sales | `SUM(net_sales)` |
| Gross Profit | `SUM(net_sales - quantity * unit_cost)` |
| Gross Margin % | `Gross Profit / Net Sales * 100` |

**Query:** [`level3_store_profitability.sql`](level3_store_profitability.sql)

**Result**

| store | net_sales | gross_profit | gross_margin_pct | rank by sales | rank by margin |
|---|---|---|---|---|---|
| S03 Jeddah Mall | 18,145 | 7,125 | 39.27 | 4 | 1 |
| S01 Riyadh Central | 21,670 | 8,500 | 39.22 | 3 | 2 |
| S02 Riyadh North | 31,047 | 12,019 | 38.71 | 1 | 3 |
| S05 Dammam Central | 11,558 | 4,386 | 37.95 | 6 | 4 |
| S04 Jeddah Corniche | 26,967 | 10,191 | 37.79 | 2 | 5 |
| S06 Khobar Express | 11,583 | 4,282 | 36.97 | 5 | 6 |

**Insight:** S02 is #1 in sales and gross profit, but only #3 in margin (38.7%). The company average margin is 38.4%, so S02 is strong, just not the margin leader.

**Validation:** total net sales after the three joins equals the raw `fact_sales` total (120,970), so no rows were dropped or duplicated.

> Practice dataset (synthetic data), not real business results.

## Level 4: Window functions + margin analysis

Four challenges in [`level4_advanced_analytics.sql`](level4_advanced_analytics.sql).

| # | Business question | SQL skill | Key result |
|---|---|---|---|
| 1 | How did total sales change month to month? | `LAG()` | Feb -31.7%, then Mar +23.1% (Jan 47,921 -> Feb 32,738 -> Mar 40,311) |
| 2 | Who are the top 3 customers in each store? | `ROW_NUMBER()` + `PARTITION BY` | Biggest spender: C152 in S02 with 1,857 |
| 3 | Which categories and products keep the most of each sale? | JOIN + margin KPI | Personal Care 46.8% margin, Grocery 35.7% |
| 4 | How do the three ranking functions differ? | `ROW_NUMBER`, `RANK`, `DENSE_RANK` | See below |

**Margin by category** (`gross_profit = net_sales - quantity * unit_cost`)

| category | net_sales | gross_profit | gross_margin_pct |
|---|---|---|---|
| Personal Care | 20,937 | 9,801 | 46.8 |
| Beverages | 7,798 | 3,178 | 40.8 |
| Household | 10,113 | 3,808 | 37.7 |
| Electronics | 29,925 | 11,085 | 37.0 |
| Grocery | 52,197 | 18,631 | 35.7 |

**Insight:** Grocery is the biggest category but has the lowest margin. Personal Care is smaller but keeps the most of each sale.

**RANK vs DENSE_RANK vs ROW_NUMBER** (customers ranked by purchases, store S01)

| customer_id | purchases | row_number_rank | rank_with_gaps | dense_rank_no_gaps |
|---|---|---|---|---|
| C117 | 5 | 1 | 1 | 1 |
| C101 | 4 | 2 | 2 | 2 |
| C116 | 4 | 3 | 2 | 2 |
| C155 | 4 | 4 | 2 | 2 |
| C105 | 3 | 5 | 5 | 3 |
| C106 | 3 | 6 | 5 | 3 |

- `ROW_NUMBER` (`row_number_rank`) never ties, so it needs a tie-breaker (here `customer_id`).
- `RANK` (`rank_with_gaps`) shares a rank for ties, then skips numbers (1, 2, 2, 2, 5).
- `DENSE_RANK` (`dense_rank_no_gaps`) shares a rank for ties, with no gaps (1, 2, 2, 2, 3).

## Level 5: Trends, segments and gaps

Four challenges in [`level5_trends_and_segments.sql`](level5_trends_and_segments.sql).

| # | Business question | SQL skill | Key result |
|---|---|---|---|
| 1 | How do daily sales build up, and what is the recent trend? | `SUM() OVER` + `AVG() OVER` with `ROWS BETWEEN` | Running total ends at 120,970 = total net sales |
| 2 | Who shops every month, and how much more do they spend? | `COUNT(DISTINCT)` + `CASE` | 48 of 60 customers are Loyal and bring 90% of sales |
| 3 | Which products has each store never sold? | `CROSS JOIN` + `LEFT JOIN` + `IS NULL` | 5 of 96 store-product pairs never sold |
| 4 | Which products surged from February to March? | Conditional aggregation (`CASE` inside `SUM`) | Orange Juice +265.9% |

**Loyal vs occasional customers** (Loyal = active in all 3 months)

| customer_type | customers | net_sales | avg_net_sales_per_customer |
|---|---|---|---|
| Loyal | 48 | 108,975 | 2,270.3 |
| Occasional | 12 | 11,995 | 999.6 |

**Store and product combinations that never sold**

| store_id | store_name | product_id | product_name |
|---|---|---|---|
| S02 | Riyadh North | P007 | Air Fryer |
| S04 | Jeddah Corniche | P007 | Air Fryer |
| S05 | Dammam Central | P001 | Coffee |
| S06 | Khobar Express | P002 | Blender |
| S06 | Khobar Express | P010 | Body Lotion |

**Top 5 products by growth, February to March**

| product_name | february_sales | march_sales | growth_pct |
|---|---|---|---|
| Orange Juice | 375 | 1,372 | 265.9 |
| Electric Kettle | 684 | 2,234 | 226.6 |
| Mineral Water Pack | 945 | 3,019 | 219.5 |
| Olive Oil | 2,657 | 6,593 | 148.1 |
| Dates | 3,216 | 7,159 | 122.6 |

**Notes**

- `ROWS BETWEEN 6 PRECEDING AND CURRENT ROW` is a 7-day window here because every day has sales.
- `AVG()` of an `INT` column drops decimals in SQL Server, so the query multiplies by `1.0` first.
- A growth % needs context: Orange Juice grew from a small base (375 to 1,372). Biggest drops were Blender (-100%), Toothpaste (-91.8%) and Shampoo (-59.0%).

## Level 6: Pareto, cohorts, weekdays and store shares

Four challenges in [`level6_pareto_and_shares.sql`](level6_pareto_and_shares.sql).

| # | Business question | SQL skill | Key result |
|---|---|---|---|
| 1 | Which products make up 80% of sales? | Running `SUM() OVER` + `CASE` | 10 of 16 products (62%) reach 80%, so not a strict 80/20 |
| 2 | How many customers are new vs returning each month? | `MIN()` per customer + conditional `SUM` | By March, 57 of 59 active customers were returning |
| 3 | Which weekday is best and worst for each store? | `DATENAME` + two `RANK()` calls | Friday is best in 3 of 6 stores, Tuesday worst in 4 |
| 4 | What share of each category does each store hold? | `SUM() OVER (PARTITION BY ...)` | S02 leads 3 of 5 categories |

**Pareto: products ranked by sales** (first 11 of 16 rows)

| product_name | net_sales | cumulative_pct | pareto_group |
|---|---|---|---|
| Dates | 15,110 | 12.5 | Core 80% |
| Basmati Rice | 13,550 | 23.7 | Core 80% |
| Coffee | 12,226 | 33.8 | Core 80% |
| Olive Oil | 11,311 | 43.1 | Core 80% |
| Headphones | 10,923 | 52.2 | Core 80% |
| Shampoo | 8,187 | 58.9 | Core 80% |
| Electric Kettle | 7,547 | 65.2 | Core 80% |
| Laundry Detergent | 7,463 | 71.4 | Core 80% |
| Blender | 7,251 | 77.3 | Core 80% |
| Body Lotion | 6,071 | 82.4 | Core 80% |
| Mineral Water Pack | 5,769 | 87.1 | Tail |

**New vs returning customers**

| sales_month | active_customers | new_customers | returning_customers |
|---|---|---|---|
| 1 | 54 | 54 | 0 |
| 2 | 53 | 4 | 49 |
| 3 | 59 | 2 | 57 |

**Best and worst weekday per store**

| store_id | weekday_name | net_sales | day_type |
|---|---|---|---|
| S01 | Friday | 5,642 | Best |
| S01 | Tuesday | 1,106 | Worst |
| S02 | Friday | 5,204 | Best |
| S02 | Tuesday | 2,956 | Worst |
| S03 | Wednesday | 3,968 | Best |
| S03 | Thursday | 1,291 | Worst |
| S04 | Friday | 6,198 | Best |
| S04 | Tuesday | 1,934 | Worst |
| S05 | Sunday | 2,722 | Best |
| S05 | Thursday | 972 | Worst |
| S06 | Saturday | 3,685 | Best |
| S06 | Tuesday | 104 | Worst |

**Leading store in each category**

| category | store_id | net_sales | category_share_pct | store_rank |
|---|---|---|---|---|
| Beverages | S01 | 2,135 | 27.4 | 1 |
| Electronics | S02 | 8,967 | 30.0 | 1 |
| Grocery | S02 | 14,832 | 28.4 | 1 |
| Household | S04 | 3,166 | 31.3 | 1 |
| Personal Care | S02 | 4,713 | 22.5 | 1 |

**Notes**

- Pareto is a test, not a law: this dataset is spread evenly, so it takes 62% of the products to reach 80% of sales.
- The data starts in January, so every January customer counts as new by definition.
- `DATENAME(weekday, ...)` returns the day name in the session language (English by default).
- Fair comparison: Tuesday occurs 12 times in Jan 1 - Mar 31, 2025 and the other weekdays 13 times, so compare average sales per day before drawing conclusions.
- Shares inside one category add up to 100 (rounding can show 100.1).

## What I learned

- `GROUP BY` collapses rows into one per group. A window function ranks rows **without** collapsing them.
- A CTE makes an aggregate-then-rank query much easier to read.
- Sales rank alone can hide profitability. Always check margin as well.
- Validate your joins: totals before and after the joins must match.
- Protect divisions with `NULLIF` so a zero never breaks a KPI.
- `LAG()` compares a row with the previous one, with no self-join needed.
- `ROW_NUMBER` + `PARTITION BY` gives top N per group. Add a tie-breaker.
- The biggest category is not always the most profitable.
- `ROWS BETWEEN` controls a window frame. Multiply by `1.0` before `AVG()` on integers.
- `CROSS JOIN` + `LEFT JOIN` + `IS NULL` finds what never happened.
- A growth percentage needs context: check the starting size.
- Pareto is a test, not a law. Check how concentrated your sales really are.
- A running `SUM() OVER` turns a ranking into a cumulative share.
- `SUM() OVER (PARTITION BY ...)` gives shares without a self-join.
- Compare fairly: check that periods contain equal numbers of days.
- Mistakes I caught in my own first drafts:
  - `BETWEEN '...' AND '2025-01-10'` can miss late-day rows if the column has a time part. Use `>= start AND < next day`.
  - A `GROUP BY` with no aggregate is unnecessary. I removed it from the CASE query.
  - `<= 499.99` leaves a gap. Use `< 500` instead.

## Next challenges

- Average daily sales per weekday (a fair weekday comparison)
- Month-to-month customer retention rate
- Do discounted sales have a different average transaction value?
- Rank stores inside each city (Riyadh and Jeddah have two stores each)

## Author

**Abu Hozaifa** | [LinkedIn](https://www.linkedin.com/in/abu-hozaifa-retail-analyst)

Feedback is welcome. I'm still learning.
