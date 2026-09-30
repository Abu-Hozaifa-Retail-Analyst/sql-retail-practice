# Retail SQL Practice (SQL Server)

Five real-world retail questions, five SQL skills. Each query answers a question a Sales, Store or Category Manager might ask.

> The dataset is **synthetic** (made up for practice). No real company data is used.

## What's inside

| File | Purpose |
|---|---|
| `setup.sql` | Creates the database, tables and all sample data (run this first) |
| `queries.sql` | The 5 solved queries with the business question above each one |
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

## What I learned

- `GROUP BY` collapses rows into one per group. A window function ranks rows **without** collapsing them.
- A CTE makes an aggregate-then-rank query much easier to read.
- Mistakes I caught in my own first drafts:
  - `BETWEEN '...' AND '2025-01-10'` can miss late-day rows if the column has a time part. Use `>= start AND < next day`.
  - A `GROUP BY` with no aggregate is unnecessary. I removed it from the CASE query.
  - `<= 499.99` leaves a gap. Use `< 500` instead.

## Next challenges

- Month-over-month sales growth with `LAG()`
- Top 3 customers per store with `ROW_NUMBER()`
- Profit margin per product using `unit_cost`
- Compare `RANK`, `DENSE_RANK` and `ROW_NUMBER` on the same data

## Author

**[Abu Hozaifa]** |www.linkedin.com/in/abu-hozaifa-retail-analyst


Feedback is welcome. I'm still learning.
