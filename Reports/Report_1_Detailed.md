# Report 1 — Customer Value & Seller Performance

## 1. Stakeholder

**Primary Stakeholders:**

* Marketing & Sales Director
* Seller Operations Team

---

## 2. Business Problem

The leadership team wants to identify our most valuable repeat customers and understand which sellers are driving that value.

Right now, the business does not have clear visibility into:

* Who the loyal repeat customers are.
* Which sellers these customers purchase from most often.
* Which orders represent their highest-value purchases.
* Whether these customers are satisfied with their purchases.

The report focuses on customers who have placed **3 or more valid orders** and combines their purchasing behavior, preferred seller, highest-value orders, and average review score.

---

## 3. Report Requirement

For every customer who has placed **3 or more orders**, the report should provide:

1. Customer ID
2. Customer city
3. Total number of orders
4. Seller they purchase from most often
5. Number of orders placed with that seller
6. Their top 3 highest-value orders
7. Value of each of those orders
8. Average review score
9. Customers without reviews should still appear as **"No Review"**

### Definition of Highest-Value Order

Order value is calculated using:

**Product Price + Freight Value**

This means the report considers both the product amount and shipping cost when identifying the customer's highest-value orders.

---

## 4. Business Use

Marketing can use this report to build loyalty and retention campaigns targeting high-value repeat customers.

Seller Operations can use it to identify:

* Sellers consistently winning repeat business.
* Sellers associated with high-value customers.
* High-spending customers who may have low satisfaction.
* High-value customers who have not provided a review.

This allows the business to combine customer value, seller preference, and satisfaction when planning retention and seller-performance activities.

---

# 5. Tables Used

| Table           | Purpose                                                                                        |
| --------------- | ---------------------------------------------------------------------------------------------- |
| `customers`     | Provides customer identifiers, unique customer IDs, city, and customer-to-order relationships. |
| `orders1`       | Provides order status, order dates, and order-level information.                               |
| `order_items`   | Provides seller IDs, product prices, and freight values for each order item.                   |
| `order_reviews` | Provides customer review scores associated with orders.                                        |

---

# 6. CTE Pipeline

The report is built using five Common Table Expressions (CTEs).

```text
                    customers
                        │
                        ▼
                   orders1
                        │
                        ▼
                 valid_orders
                        │
                        ▼
                  customer_rec
                        │
                        ├──────────────────────────┐
                        │                          │
                        ▼                          ▼
                  top_sellers              top3_high_prices
                        │                          │
                        │                          │
                        └──────────────┬───────────┘
                                       │
                                       ▼
                                  avg_review
                                       │
                                       ▼
                              Final Report Output
```

The CTEs perform different analytical tasks before being combined in the final query.

---

## 6.1 `valid_orders`

### Purpose

The first CTE filters out orders that should not be considered valid for the repeat-customer analysis.

### Logic

```sql
with valid_orders as (
    select *
    from orders1
    where order_status not in ('unavailable', 'cancelled')
)
```

### What It Does

* Reads order information from `orders1`.
* Excludes orders with status:

  * `unavailable`
  * `cancelled`

Only the remaining orders are passed to the next stages of the analysis.

### Why It Matters

Cancelled and unavailable orders should not contribute to a customer's purchasing history when identifying repeat customers and their purchasing behavior.

---

## 6.2 `customer_rec`

### Purpose

Identifies customers who have placed **3 or more valid orders**.

### Main Logic

The CTE joins `customers` with `valid_orders` using `customer_id`.

It then:

* Groups records by `customer_unique_id`.
* Retrieves the customer's city.
* Counts distinct valid orders.
* Keeps only customers with at least 3 valid orders.

### Key SQL Logic

```sql
group by c.customer_unique_id
having count(distinct vo.order_id) >= 3
```

### Why `customer_unique_id` Is Used

The dataset can contain multiple customer records associated with the same real customer across orders.

Using `customer_unique_id` allows the analysis to identify repeat purchasing behavior at the unique-customer level.

### Output from This CTE

| Column               | Meaning                                       |
| -------------------- | --------------------------------------------- |
| `customer_unique_id` | Unique customer identifier                    |
| `customer_city`      | Customer's city                               |
| `total_orders`       | Number of valid orders placed by the customer |

---

## 6.3 `top_sellers`

### Purpose

Identifies the seller from whom each repeat customer has purchased most frequently.

### Logic

The CTE connects:

```text
customers
    ↓
valid_orders
    ↓
order_items
```

It counts distinct orders for every:

**Customer + Seller**

combination.

### Ranking Logic

```sql
row_number() over(
    partition by customer_unique_id
    order by count(distinct oi.order_id) desc,
             oi.seller_id
)
```

### What It Does

For each customer:

1. Sellers are grouped according to the customer's orders.
2. Sellers are ordered by the number of distinct orders.
3. The seller with the highest number of orders receives `rno = 1`.
4. Only `rno = 1` is retained.

### Tie-Breaking

If two sellers have the same number of orders, `seller_id` is used as the secondary sorting column.

This makes the ranking deterministic rather than leaving the tie unresolved.

### Output from This CTE

| Column               | Meaning                                          |
| -------------------- | ------------------------------------------------ |
| `customer_unique_id` | Unique customer                                  |
| `seller_id`          | Customer's most frequently purchased-from seller |
| `orders`             | Number of orders placed with that seller         |

---

## 6.4 `top3_high_prices`

### Purpose

Identifies the customer's **three highest-value orders**.

### Order Value Calculation

For each customer and order, the query calculates:

```sql
sum(price + freight_value)
```

Therefore:

**Order Value = Product Price + Freight Value**

### Ranking Logic

```sql
row_number() over(
    partition by customer_unique_id
    order by sum(price + freight_value) desc,
             oi.order_id
)
```

### What It Does

For each customer:

1. Calculates the total value of each order.
2. Includes both product price and freight value.
3. Ranks orders from highest value to lowest value.
4. Keeps only ranks 1, 2, and 3.

```sql
where rn <= 3
```

### Output from This CTE

| Column                  | Meaning                             |
| ----------------------- | ----------------------------------- |
| `customer_unique_id`    | Unique customer                     |
| `order_id`              | High-value order ID                 |
| `prices`                | Total order value including freight |
| `rank_of_highest_price` | Rank from 1 to 3                    |

---

## 6.5 `avg_review`

### Purpose

Calculates the average review score for each customer.

### Join Strategy

The CTE uses a **LEFT JOIN** between:

```text
customers
    ↓
valid_orders
    ↓
order_reviews
```

### Why LEFT JOIN Is Important

A customer may have placed valid orders but may not have submitted a review.

Using a left join allows customers without reviews to remain in the analysis.

### Review Calculation

```sql
avg(review_score)
```

The average review score is rounded to two decimal places, converted to text using `CAST`, and replaced with `No Review` using `COALESCE` when no review score is available.

```sql
coalesce(cast(round(avg(review_score),2) as varchar2(20)), 'No Review')
```

Therefore, customers without available reviews are displayed as:

**No Review**

rather than being excluded from the report.

---

# 7. Final Query Logic

After all five CTEs are created, they are combined using `LEFT JOIN`.

```text
customer_rec
     │
     ├── top_sellers
     │
     ├── top3_high_prices
     │
     └── avg_review
```

`customer_rec` acts as the base population because it contains only customers who have placed at least three valid orders.

### Why LEFT JOIN Is Used

Using `LEFT JOIN` ensures that repeat customers remain in the final report even if some additional information is unavailable.

For example:

* A repeat customer without a review still appears.

---

## Pivoting the Top 3 Orders

The final query converts the three ranked order records into separate columns using conditional aggregation.

Example:

```sql
max(
    case
        when thp.rank_of_highest_price = 1
        then thp.order_id
    end
) as top_order_1
```

The same approach is used for ranks 1, 2, and 3.

This transforms the data from:

```text
Customer | Rank | Order
---------|------|------
A        | 1    | O101
A        | 2    | O205
A        | 3    | O309
```

into:

```text
Customer | Top Order 1 | Top Order 2 | Top Order 3
---------|-------------|-------------|-------------
A        | O101        | O205        | O309
```

This makes the final report easier for business users to consume.

---

# 8. Output Columns

| Column                   | Description                                         |
| ------------------------ | --------------------------------------------------- |
| `customer_unique_id`     | Unique identifier of the repeat customer            |
| `customer_city`          | Customer's city                                     |
| `total_orders`           | Total number of valid orders placed by the customer |
| `seller_id`              | Seller purchased from most frequently               |
| `top_seller_order_count` | Number of orders placed with the top seller         |
| `top_order_1`            | Highest-value order ID                              |
| `top_order_1_value`      | Value of the highest-value order, including freight |
| `top_order_2`            | Second-highest-value order ID                       |
| `top_order_2_value`      | Value of the second-highest-value order             |
| `top_order_3`            | Third-highest-value order ID                        |
| `top_order_3_value`      | Value of the third-highest-value order              |
| `final_review`           | Average review score or `No Review`                 |

---

# 9. Business Interpretation

This report creates a customer-level view of repeat purchasing behavior.

It enables the business to identify:

* Customers with demonstrated repeat purchasing behavior.
* The seller each repeat customer purchases from most frequently.
* The customer's highest-value orders, including freight costs.
* The satisfaction level associated with the customer's orders.
* Repeat customers who have not submitted reviews.

### Marketing & Sales

The report can support targeted retention and loyalty initiatives by providing a list of customers with at least three valid orders and additional information about their purchasing behavior.

### Seller Operations

The report can help identify which sellers are repeatedly serving high-value customers.

### Customer Experience

Combining order value with review scores allows the business to identify situations where a customer has significant purchasing activity but relatively low satisfaction.

---

# 10. SQL Concepts Used

| SQL Concept       | Application                                                                    |
| ----------------- | ------------------------------------------------------------------------------ |
| CTEs              | Break the analysis into logical transformation stages                          |
| INNER JOIN        | Combine customers, orders, and order items where matching records are required |
| LEFT JOIN         | Preserve repeat customers even when review information is unavailable          |
| `COUNT(DISTINCT)` | Count unique orders                                                            |
| `HAVING`          | Filter customers with at least 3 orders                                        |
| `ROW_NUMBER()`    | Rank sellers and high-value orders                                             |
| `PARTITION BY`    | Perform rankings separately for each customer                                  |
| `CASE WHEN`       | Apply conditional logic and pivot ranked orders                                |
| `MAX()`           | Convert ranked rows into final report columns                                  |
| `COALESCE()`      | Display `No Review` when review data is unavailable                            |
| `ROUND()`         | Control numerical precision                                                    |
| `CAST()`          | Convert the review result to text for displaying `No Review`                   |

---

# 11. Output Preview

The final query produces a customer-level report containing repeat-customer activity, top seller information, the three highest-value orders, and review information.

Example structure:

```text
customer_unique_id | customer_city | total_orders | seller_id | top_seller_order_count | top_order_1 | top_order_1_value | final_review
```

The actual report output is stored separately as the Report 1 result dataset.

---

# 12. Report Flow Summary

```text
Raw Olist Tables
       │
       ▼
Filter Invalid Orders
       │
       ▼
Identify Repeat Customers (3+ Orders)
       │
       ├──────────────► Identify Top Seller
       │
       ├──────────────► Identify Top 3 High-Value Orders
       │
       └──────────────► Calculate Average Review
       │
       ▼
Combine Customer Intelligence
       │
       ▼
Customer Value & Seller Performance Report
```

---

# 13. SQL Implementation

The complete executable Oracle SQL for this report is available in the main project SQL file:

**[View Complete SQL Implementation](../sql-capstone-multi-table-ecommerce-analysis.sql)**

The SQL implementation contains the complete CTE pipeline and final customer value and seller performance query.

## 14. Report Output

**[View Report 1 Output PDF](../Outputs/PDF/Report_1_Output.pdf)**
