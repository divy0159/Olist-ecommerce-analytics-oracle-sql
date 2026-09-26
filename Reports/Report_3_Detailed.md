# Report 3 — Delivery Performance by Region

## 1. Stakeholder

**Primary Stakeholders:**

* Head of Customer Support
* Operations Team

---

# 2. Business Problem

Customer Support has been receiving complaints about late deliveries, but the business does not have clear visibility into whether delivery delays are concentrated in specific states or occur more broadly across the marketplace.

The business needs to understand:

* How many orders are placed in each customer state.
* How long orders take to reach customers.
* What percentage of orders are delivered later than the estimated delivery date.
* Whether delivery performance differs across states.
* Whether delivery delays are associated with lower customer review scores.

The report analyzes delivery performance at the customer-state level and combines order volume, delivery time, late-delivery rate, and customer satisfaction into a single regional view.

---

# 3. Report Requirement

For every customer state, the report provides:

1. Total number of orders
2. Average delivery time from purchase to actual delivery
3. Percentage of orders delivered later than the estimated delivery date
4. Average customer review score

The report uses the customer's state as the geographic dimension for comparing delivery performance.

### Definition of Average Delivery Time

Average delivery time is calculated as:

**Actual Delivery Date − Order Purchase Timestamp**

The result represents the average number of days between when an order was placed and when it was delivered to the customer.

Only orders with a non-null actual delivery date are included in this calculation.

### Definition of Late Delivery

An order is considered late when:

**Actual Delivery Date > Estimated Delivery Date**

The late-delivery percentage is calculated as:

**Late Orders ÷ Delivered Orders × 100**

Only orders with a non-null actual delivery date are included.

### Definition of Average Review Score

The average review score is calculated from customer reviews associated with delivered orders within each state.

The review score ranges from **1 to 5**, where higher scores represent more positive customer reviews.

---

# 4. Business Use

Customer Support can use this report to identify states where delivery delays may be more frequent.

The Operations team can use it to investigate:

* States with high late-delivery percentages.
* States with longer average delivery times.
* Differences in delivery performance across regions.
* Whether lower review scores appear alongside delivery delays.

The report provides regional visibility that can support investigation of:

* Logistics performance.
* Courier-partner performance.
* Regional delivery constraints.
* Operational bottlenecks.
* Customer-service issues associated with delayed deliveries.

The report helps distinguish regional delivery patterns from isolated delivery incidents.

---

# 5. Tables Used

| Table           | Purpose                                                                                            |
| --------------- | -------------------------------------------------------------------------------------------------- |
| `customers`     | Provides customer information, including the customer's state and customer-to-order relationship.  |
| `orders1`       | Provides order timestamps, estimated delivery dates, actual delivery dates, and order identifiers. |
| `order_reviews` | Provides customer review scores associated with orders.                                            |

---

# 6. CTE Pipeline

The report is built using four Common Table Expressions (CTEs).

```text
customers
    │
    ├──────────────────────┐
    │                      │
    ▼                      ▼
orders1              order_reviews
    │                      │
    ├──────────────┐       │
    │              │       │
    ▼              ▼       │
state_ordersplaced deli_days
    │              │       │
    │              │       │
    │              │       ▼
    │              │    avg_rev
    │              │       │
    │              │       │
    │              ▼       │
    │            Metrics   │
    │                      │
    └──────────┬───────────┘
               │
               ▼
             est_del
               │
               ▼
       Final State Report
```

The four CTEs perform separate analytical tasks before being combined in the final query.

* `state_ordersplaced` calculates the total number of orders for each customer state.
* `deli_days` calculates the average delivery time for each state.
* `avg_rev` calculates the average customer review score for each state.
* `est_del` calculates the percentage of delivered orders that arrived later than the estimated delivery date.
* The final query joins these state-level metrics into a single report.

---

## 6.1 `state_ordersplaced`

### Purpose

Calculates the total number of orders placed in each customer state.

### Main Logic

The CTE joins `customers` with `orders1` using `customer_id`.

```sql
customers c
join orders1 o1
on c.customer_id = o1.customer_id
```

The results are grouped by:

```sql
customer_state
```

### Key SQL Logic

```sql
select c.customer_state,
       count(distinct o1.order_id) as orders_placed
from customers c
join orders1 o1
on c.customer_id = o1.customer_id
group by customer_state
```

### What It Does

* Connects each order with the customer's state.
* Counts distinct orders for each state.
* Creates the order-volume baseline used by the final report.

### Why It Matters

Order volume provides context for interpreting the other regional metrics.

A state with a high number of orders represents a larger portion of the marketplace's order activity.

### Output from this CTE

| Column           | Meaning                                             |
| ---------------- | --------------------------------------------------- |
| `customer_state` | Customer's state                                    |
| `orders_placed`  | Number of distinct orders associated with the state |

---

## 6.2 `deli_days`

### Purpose

Calculates the average number of days between order purchase and actual customer delivery for each state.

### Logic

The CTE joins `orders1` with `customers` using `customer_id`.

Only orders with an actual delivery date are included.

```sql
where order_delivered_customer_date is not null
```

### Key SQL Logic

```sql
select c.customer_state,
       round(
           avg(
               order_delivered_customer_date
               - order_purchase_timestamp
           ),
           1
       ) as avg_days
from orders1 o1
join customers c
on o1.customer_id = c.customer_id
where order_delivered_customer_date is not null
group by customer_state
```

### Delivery Time Calculation

The query calculates:

**Order Delivered Date − Order Purchase Timestamp**

```sql
order_delivered_customer_date - order_purchase_timestamp
```

The average is then calculated for each state.

```sql
avg(
    order_delivered_customer_date
    - order_purchase_timestamp
)
```

The result is rounded to one decimal place.

### Why It Matters

Average delivery time provides a direct measure of how long customers typically wait for their orders in each state.

### Output from this CTE

| Column           | Meaning                                          |
| ---------------- | ------------------------------------------------ |
| `customer_state` | Customer's state                                 |
| `avg_days`       | Average number of days from purchase to delivery |

---

## 6.3 `avg_rev`

### Purpose

Calculates the average customer review score for each state.

### Logic

The CTE connects:

```text
order_reviews
       │
       ▼
orders1
       │
       ▼
customers
```

The joins connect each review to its order and then connect the order to the customer's state.

Only orders with a non-null actual delivery date are included.

```sql
where order_delivered_customer_date is not null
```

### Key SQL Logic

```sql
select c.customer_state,
       round(avg(review_score),2) as Avg_review
from order_reviews ors
join orders1 o1
on ors.order_id = o1.order_id
join customers c
on c.customer_id = o1.customer_id
where order_delivered_customer_date is not null
group by customer_state
```

### Average Review Calculation

The query calculates:

```sql
avg(review_score)
```

for each customer state.

The result is rounded to two decimal places:

```sql
round(avg(review_score),2)
```

### Why It Matters

Review scores provide a customer-satisfaction measure that can be compared with regional delivery performance.

### Output from this CTE

| Column           | Meaning                       |
| ---------------- | ----------------------------- |
| `customer_state` | Customer's state              |
| `Avg_review`     | Average customer review score |

---

## 6.4 `est_del`

### Purpose

Calculates the percentage of delivered orders that arrived later than the estimated delivery date for each state.

### Logic

The CTE joins `orders1` with `customers` using `customer_id`.

Only orders with an actual delivery date are included.

For each order, the query checks whether:

```sql
order_delivered_customer_date > order_estimated_delivery_date
```

### Key SQL Logic

```sql
select c.customer_state,
       round(
           100.0 *
           sum(
               case
                   when order_delivered_customer_date >
                        order_estimated_delivery_date
                   then 1
                   else 0
               end
           ) / count(*),
           1
       ) as order_pct
from orders1 o1
join customers c
on o1.customer_id = c.customer_id
where order_delivered_customer_date is not null
group by customer_state
```

### Late Order Identification

The `CASE` expression assigns:

```text
1 → Delivered after estimated date
0 → Delivered on or before estimated date
```

```sql
case
    when order_delivered_customer_date >
         order_estimated_delivery_date
    then 1
    else 0
end
```

### Late Delivery Percentage

The percentage is calculated as:

**Late Delivered Orders ÷ Total Delivered Orders × 100**

```sql
100.0 * sum(late_order_flag) / count(*)
```

The result is rounded to one decimal place.

### Why It Matters

This metric identifies the proportion of delivered orders that missed the estimated delivery date.

It allows delivery performance to be compared across customer states.

### Output from this CTE

| Column           | Meaning                                                           |
| ---------------- | ----------------------------------------------------------------- |
| `customer_state` | Customer's state                                                  |
| `order_pct`      | Percentage of delivered orders delivered after the estimated date |

---

# 7. Final Query Logic

After the four CTEs are created, their state-level results are combined using `LEFT JOIN`.

```text
state_ordersplaced
        │
        ├──────────────► deli_days
        │
        ├──────────────► avg_rev
        │
        └──────────────► est_del
                         │
                         ▼
                  Final State Report
```

The final query starts with `state_ordersplaced`:

```sql
from state_ordersplaced so
```

and joins the other CTEs using `customer_state`.

```sql
left join deli_days di
on so.customer_state = di.customer_state

left join avg_rev ar
on so.customer_state = ar.customer_state

left join est_del es
on so.customer_state = es.customer_state
```

This creates one combined record for each customer state.

---

## Total Orders

The final report uses:

```sql
so.orders_placed
```

This represents the number of distinct orders associated with each customer state.

The calculation comes from:

```sql
count(distinct o1.order_id)
```

in the `state_ordersplaced` CTE.

---

## Average Delivery Time

The final report uses:

```sql
di.avg_days
```

This represents the average number of days between order purchase and actual delivery.

The calculation comes from:

```sql
round(
    avg(
        order_delivered_customer_date
        - order_purchase_timestamp
    ),
    1
)
```

---

## Average Review Score

The final report uses:

```sql
ar.Avg_review
```

This represents the average review score for delivered orders associated with customers in each state.

The result is rounded to two decimal places.

---

## Late Delivery Percentage

The final report uses:

```sql
es.order_pct
```

This represents the percentage of delivered orders that arrived after the estimated delivery date.

The result is rounded to one decimal place.

---

## State-Level Combination

The final output combines:

```text
Order Volume
     +
Average Delivery Time
     +
Average Review Score
     +
Late Delivery Percentage
     ↓
State-Level Delivery Performance
```

This provides a single regional view of delivery performance and customer satisfaction.

---

## Ordering

The final report is ordered by:

```sql
order by customer_state
```

Therefore, the states appear in alphabetical order.

---

# 8. Output Columns

| Column           | Description                                                                |
| ---------------- | -------------------------------------------------------------------------- |
| `customer_state` | Customer's state                                                           |
| `orders_placed`  | Number of distinct orders associated with the state                        |
| `avg_days`       | Average number of days from purchase to actual delivery                    |
| `Avg_review`     | Average customer review score for delivered orders                         |
| `order_pct`      | Percentage of delivered orders delivered after the estimated delivery date |

---

# 9. Business Interpretation

This report creates a state-level view of delivery performance and customer satisfaction.

It enables the business to identify:

* States with higher order volumes.
* States with longer average delivery times.
* States with higher late-delivery percentages.
* Differences in customer review scores across states.
* Regional patterns between delivery performance and customer satisfaction.

### Customer Support

Customer Support can use the report to understand where delivery-related complaints may be more concentrated.

States with higher late-delivery percentages can be examined alongside their review scores to understand the customer-experience impact.

### Operations Team

Operations can use the report to investigate regional delivery performance and identify states that may require further logistics analysis.

The information can support investigation of:

* Regional courier performance.
* Delivery bottlenecks.
* Logistics constraints.
* Estimated delivery-date accuracy.
* Regional operational differences.

### Customer Satisfaction

The combination of late-delivery percentage and average review score provides a way to examine whether regions with more delivery delays also show differences in customer satisfaction.

The report identifies regional patterns; additional analysis is required to establish whether delivery delays directly cause lower review scores.

---

# 10. SQL Concepts Used

| SQL Concept       | Application                                                                                      |
| ----------------- | ------------------------------------------------------------------------------------------------ |
| CTEs              | Separate order volume, delivery time, review, and late-delivery calculations into logical stages |
| `JOIN`            | Connect customers, orders, and reviews                                                           |
| `LEFT JOIN`       | Combine state-level metrics while retaining states from the primary order-volume dataset         |
| `GROUP BY`        | Aggregate metrics by customer state                                                              |
| `COUNT(DISTINCT)` | Count unique orders for each state                                                               |
| `AVG()`           | Calculate average delivery time and review scores                                                |
| `SUM()`           | Count late-delivery records using conditional aggregation                                        |
| `CASE WHEN`       | Identify orders delivered after the estimated date                                               |
| Date arithmetic   | Calculate delivery time from purchase to actual delivery                                         |
| `ROUND()`         | Control numerical precision                                                                      |
| `ORDER BY`        | Sort the final report by customer state                                                          |

---

# 11. Output Preview

The final query produces a state-level report containing:

* Customer state
* Total order volume
* Average delivery time
* Average review score
* Late-delivery percentage

The report combines operational delivery metrics with customer satisfaction metrics to provide a regional view of delivery performance.

---

# 12. Report Flow Summary

```text
Raw Olist Tables
       │
       ▼
Identify Customer States
       │
       ├──────────────► Count Orders by State
       │
       ├──────────────► Calculate Average Delivery Time
       │
       ├──────────────► Calculate Average Review Score
       │
       └──────────────► Calculate Late Delivery Percentage
       │
       ▼
Combine State-Level Metrics
       │
       ▼
State-Level Delivery Performance
       │
       ▼
Delivery Performance by Region Report
```

## 13. SQL Implementation

The complete Oracle SQL implementation for this report is available in the main project SQL file.

[View Complete SQL Implementation](../sql-capstone-multi-table-ecommerce-analysis.sql)

## 14. Report Output

**[View Report 3 Output PDF](../Outputs/Report_3_Output.pdf)**
