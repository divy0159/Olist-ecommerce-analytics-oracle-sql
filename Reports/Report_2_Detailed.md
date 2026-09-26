# Report 2 — Product Category Performance & Shipping Cost Risk

## 1. Stakeholder

**Primary Stakeholders:**

* Finance Manager
* Pricing Team

---

## 2. Business Problem

The Finance team has noticed that shipping costs may be high for certain product categories but does not have clear visibility into which categories are most affected.

The business does not have clear visibility into:

* Which product categories have high average freight costs.
* How freight costs compare with product prices.
* Which products have freight costs exceeding 30% of their average product price.
* Which categories contain a high proportion of products with high freight costs.

The report analyzes product-level price and freight information and summarizes the results at the product-category level.

---

## 3. Report Requirement

For every product category, the report provides:

1. Product category name in English
2. Total number of orders
3. Average product price
4. Average freight cost
5. Freight cost as a percentage of product price
6. Percentage of products where freight cost exceeds 30% of product price
7. Category-level freight risk flag

### Definition of Freight Cost

Freight cost is calculated using:

**Average Freight Value ÷ Average Product Price × 100**

This allows the business to compare shipping costs with the value of the products being sold.

### Definition of Freight Risk

At the product level, a product is flagged when:

**Average Freight Value > 30% of Average Product Price**

At the category level, the percentage of products meeting this condition is calculated.

A category receives a **`⚠`** flag when **50% or more of its products** exceed the 30% freight-cost threshold.

Otherwise, the category is marked as **`Ok`**.

---

## 4. Business Use

Finance can use this report to identify product categories where freight costs may represent a significant portion of product value.

The Pricing team can use it to identify:

* Categories with high average freight costs.
* Categories where freight represents a large percentage of product price.
* Categories with a high proportion of products exceeding the 30% freight threshold.
* Categories that may require further pricing or shipping-cost analysis.

The analysis provides visibility that can support investigation of:

* Pricing adjustments.
* Freight subsidy limits.
* Free-shipping policies.
* Category-level shipping strategies.

The report identifies potential shipping-cost exposure that can be investigated further by Finance and Pricing teams.

---

# 5. Tables Used

| Table              | Purpose                                                                                                       |
| ------------------ | ------------------------------------------------------------------------------------------------------------- |
| `product_category` | Provides the mapping between the original product category name and its English category name.                |
| `products1`        | Provides product information and connects products with their category names.                                 |
| `order_items`      | Provides product prices, freight values, and order-level information used to calculate shipping-cost metrics. |

---

# 6. CTE Pipeline

The report is built using two Common Table Expressions (CTEs).

```text
product_category ─────────┐
                          │
products1 ────────────────┤
                          ▼
                       prod_cat
                          │
                          │
                          │
order_items ────────► freight_cost
                          │
                          │
                          └──────────────┐
                                         │
                                         ▼
                                  Final Report Output
```

The two CTEs perform independent analytical tasks before being combined in the final query.

* `prod_cat` connects products with their English category names.
* `freight_cost` calculates product-level price, freight, order count, and freight-risk metrics.
* The final query joins both CTEs using `product_id` and aggregates the results by product category.

---

## 6.1 `prod_cat`

### Purpose

Maps the original product category names to their English category names.

### Main Logic

The CTE joins `product_category` with `products1` using the product category name.

```sql
product_category_name = product_category_name
```

### Key SQL Logic

```sql
select product_category_name_english,
       product_id
from product_category pc
join products1 p1
on pc.product_category_name = p1.product_category_name
```

### What It Does

* Connects the product category translation table with the product table.
* Retrieves the English category name.
* Keeps the product ID so the category information can later be connected with `order_items`.

### Why It Matters

The original Olist dataset contains category names in Portuguese.

Using the English category name makes the final report easier for business users to understand.

### Output from this CTE

| Column                          | Meaning                       |
| ------------------------------- | ----------------------------- |
| `product_category_name_english` | English product category name |
| `product_id`                    | Unique product identifier     |

---

## 6.2 `freight_cost`

### Purpose

Calculates product-level price, freight, order count, and freight-cost percentage.

### Logic

The CTE groups `order_items` by `product_id`.

For every product, it calculates:

* Average product price.
* Average freight value.
* Number of distinct orders.
* Freight cost as a percentage of product price.
* A freight threshold flag.

### Key SQL Logic

```sql
select product_id,
       avg(price) as avg_price,
       avg(freight_value) as avg_freight,
       count(distinct order_id) as order_count,
       round((avg(freight_value)/avg(price))*100,1) as Freight_cos,
       case
           when (avg(freight_value)/avg(price)) > 0.30
           then 1
           else 0
       end as Freight_cat
from order_items
group by product_id
```

### Average Product Price

```sql
avg(price)
```

Calculates the average price for each product.

### Average Freight Value

```sql
avg(freight_value)
```

Calculates the average freight value for each product.

### Order Count

```sql
count(distinct order_id)
```

Counts the number of distinct orders associated with each product.

### Freight Cost Percentage

The query calculates:

**Average Freight ÷ Average Product Price × 100**

```sql
round((avg(freight_value)/avg(price))*100,1)
```

The result is rounded to one decimal place.

### Freight Category Flag

The query checks whether:

```sql
(avg(freight_value)/avg(price)) > 0.30
```

If the condition is true:

```text
Freight_cat = 1
```

Otherwise:

```text
Freight_cat = 0
```

Therefore:

* `1` = Product's average freight exceeds 30% of its average price.
* `0` = Product's average freight does not exceed 30%.

### Output from this CTE

| Column        | Meaning                                               |
| ------------- | ----------------------------------------------------- |
| `product_id`  | Unique product identifier                             |
| `avg_price`   | Average product price                                 |
| `avg_freight` | Average freight value                                 |
| `order_count` | Number of distinct orders associated with the product |
| `Freight_cos` | Freight cost as a percentage of average product price |
| `Freight_cat` | Product-level freight threshold flag                  |

---

# 7. Final Query Logic

After both CTEs are created, they are combined using a `JOIN`.

```text
prod_cat
    │
    │
    ├──────────────────┐
    │                  │
    │                  ▼
    │             freight_cost
    │                  │
    └───────JOIN───────┘
              │
              ▼
    Category-Level Aggregation
              │
              ▼
       Final Report Output
```

The final query joins the two CTEs using `product_id`.

```sql
freight_cost fc
join prod_cat pt
on pt.product_id = fc.product_id
```

This connects each product's freight information with its English product category.

### Grouping by Category

The final query groups the data by:

```sql
pt.product_category_name_english
```

This converts the product-level information into category-level results.

---

## Total Orders

The query calculates:

```sql
sum(fc.order_count)
```

and displays it as:

```sql
concat(sum(fc.order_count), ' orders')
```

This represents the sum of product-level distinct order counts associated with the category.

Because the calculation is performed separately for each product before being summed, it should **not** be interpreted as a category-level `COUNT(DISTINCT order_id)`.

---

## Average Product Price

The query calculates:

```sql
round(avg(fc.avg_price),1)
```

This represents the average of the product-level average prices within the category.

---

## Average Freight Value

The query calculates:

```sql
round(avg(fc.avg_freight),1)
```

This represents the average of the product-level average freight values within the category.

---

## Freight Cost

The final query calculates:

```sql
round(avg(fc.Freight_cos),1)
```

and displays it with a `%` symbol.

This represents the average product-level freight-cost percentage within the category.

---

## Percentage of Products Above 30%

The query calculates:

```sql
round(
    100.0 * sum(fc.Freight_cat) / count(*),
    1
)
```

This determines the percentage of products within each category where freight exceeds 30% of average product price.

For example:

```text
Category contains 100 products
40 products exceed 30%
        ↓
Pct_products_over_30 = 40%
```

---

## Category Freight Flag

The final query applies:

```sql
case
    when (100.0*sum(fc.Freight_cat)/count(*)) >= 50
    then '⚠'
    else 'Ok'
end
```

Therefore:

```text
50% or more of products exceed 30%
                ↓
               ⚠
```

Otherwise:

```text
Less than 50% of products exceed 30%
                ↓
               Ok
```

This creates the category-level freight-risk indicator.

---

## Ordering

The final report is ordered by:

```sql
order by Pct_products_over_30 desc
```

Therefore, categories with a higher percentage of products exceeding the 30% threshold appear first.

---

# 8. Output Columns

| Column                     | Description                                                               |
| -------------------------- | ------------------------------------------------------------------------- |
| `Orders_placed`            | Sum of product-level distinct order counts associated with the category   |
| `category`                 | English product category name                                             |
| `Average_price_of_product` | Average of product-level average prices                                   |
| `Average_freight_value`    | Average of product-level average freight values                           |
| `Freight_cost`             | Average product-level freight-cost percentage                             |
| `Pct_products_over_30`     | Percentage of products where freight exceeds 30% of average product price |
| `Freight_flag`             | `⚠` when 50% or more of products exceed the 30% threshold; otherwise `Ok` |

---

# 9. Business Interpretation

This report creates a category-level view of product pricing and shipping-cost exposure.

It enables the business to identify:

* Product categories with higher average freight costs.
* Categories where freight represents a larger proportion of product value.
* Categories containing a high percentage of products with freight costs above 30%.
* Categories that meet the defined freight-risk threshold.

### Finance

The report can support Finance in identifying categories where shipping costs may require further investigation.

It provides visibility into the relationship between product price and freight cost.

### Pricing Team

The report can help the Pricing team investigate categories where freight represents a significant percentage of product value.

### Shipping Strategy

The results can support analysis of:

* Shipping policy changes.
* Freight subsidy limits.
* Free-shipping promotions.
* Category-level shipping strategies.

The report identifies potential shipping-cost exposure; additional financial analysis would be required to determine the actual impact on profit margins.

---

# 10. SQL Concepts Used

| SQL Concept             | Application                                                                   |
| ----------------------- | ----------------------------------------------------------------------------- |
| CTEs                    | Break the analysis into logical transformation stages                         |
| `JOIN`                  | Combine product category information with product-level freight metrics       |
| `GROUP BY`              | Aggregate product-level information by product category                       |
| `AVG()`                 | Calculate average product prices and freight values                           |
| `COUNT(DISTINCT)`       | Count unique orders for each product                                          |
| `SUM()`                 | Aggregate order counts and freight flags                                      |
| `CASE WHEN`             | Create product-level and category-level freight flags                         |
| `ROUND()`               | Control numerical precision                                                   |
| `CONCAT()`              | Add `orders` and `%` to displayed values                                      |
| Arithmetic calculations | Calculate freight cost as a percentage of product price                       |
| `ORDER BY`              | Sort categories by the percentage of products exceeding the freight threshold |

---

# 11. Output Preview

The final query produces a category-level report containing:

* Order volume
* Average product price
* Average freight value
* Freight-cost percentage
* Percentage of products exceeding the 30% freight threshold
* Category-level freight flag

---

# 12. Report Flow Summary

```text
Raw Olist Tables
       │
       ▼
Map Product Categories to English Names
       │
       ▼
Calculate Product-Level Freight Metrics
       │
       ├──────────────► Average Product Price
       │
       ├──────────────► Average Freight
       │
       ├──────────────► Order Count
       │
       └──────────────► Freight > 30% Flag
       │
       ▼
Combine Product & Category Information
       │
       ▼
Aggregate by Product Category
       │
       ▼
Calculate % Products Above 30%
       │
       ▼
Apply Category Freight Flag
       │
       ▼
Product Category Performance & Shipping Cost Risk Report
```

# 13. SQL Implementation

The complete Oracle SQL implementation for this report is available in the main project SQL file.

[View Complete SQL Implementation](../sql-capstone-multi-table-ecommerce-analysis.sql)
