## Olist-ecommerce-analytics-oracle-sql

SQL analytics project on the Olist Brazilian e-commerce dataset — 4 business-driven reports (customer value, shipping cost risk, delivery performance, seller risk scorecard) built in Oracle SQL using CTEs, window functions, and dynamic risk flagging.

## Project Overview

Olist is a growing Brazilian e-commerce marketplace connecting third-party sellers with customers across Brazil.
This project analyzes Olist's e-commerce data to provide leadership with a data-driven view of customer retention, seller performance, delivery reliability, customer satisfaction, and shipping costs.
The analysis brings together multiple business perspectives to answer a central question:
Which sellers and customers are genuinely valuable to the marketplace, and what operational factors are affecting customer trust, retention, and profitability?
The project transforms raw transactional data into four business-focused analytical reports and a unified seller intelligence view.

## 🎯 Business Problem

Olist has been experiencing declining customer retention and rising customer complaints, but leadership lacks the data-driven visibility needed to understand why.
The Marketing and Sales Director wants to identify the company's most valuable repeat customers, understand which sellers those customers keep returning to, and determine whether those customers are actually satisfied. This will allow retention and loyalty campaigns to be properly targeted instead of being based on assumptions.
At the same time, the Finance Manager has noticed shrinking margins and suspects that shipping costs for certain product categories are quietly reducing profitability. However, there is no concrete evidence to determine which categories have disproportionately high freight costs or whether shipping costs may justify changes to pricing or shipping policies.
Meanwhile, the Head of Customer Support has been receiving a growing number of complaints about late deliveries. The team needs to determine whether these delays represent a systemic regional logistics problem or are primarily caused by a smaller number of isolated incidents before escalating the issue to Operations.
Finally, company leadership wants a single, unified view of seller performance that connects these issues together.

## Leadership needs to understand:

- Which sellers are genuinely valuable to the business.
- Which sellers generate high revenue while simultaneously damaging customer trust.
- Which sellers are associated with poor delivery performance.
- Which sellers are associated with low customer satisfaction.
- Which sellers serve valuable repeat customers.
- Which product categories have disproportionately high shipping costs.
- Whether late deliveries are concentrated among particular sellers or regions.
- Whether valuable repeat customers are actually satisfied with their experience.
The ultimate goal is to create an evidence-based intelligence framework that can support decisions around seller partnerships, seller   performance management, customer retention, loyalty campaigns, shipping policies, and logistics investigation.

## 🎯 Project Objectives

The project aims to:
Identify and analyze valuable repeat customers.
Understand which sellers repeat customers purchase from.
Evaluate customer satisfaction through review behavior.
Analyze seller revenue and order performance.
Identify sellers associated with poor delivery performance.
Analyze late-delivery patterns across sellers and regions.
Identify product categories with high freight costs relative to product value.
Investigate relationships between delivery performance and customer satisfaction.
Combine seller value, customer behavior, delivery performance, and satisfaction into a unified seller view.
Provide evidence-based insights that can support business decision-making.

## 👥 Business Stakeholders

The analysis addresses the requirements of multiple business stakeholders.
Stakeholder	Business Need
Marketing & Sales Director	Identify valuable repeat customers and understand their seller preferences and satisfaction.
Finance Manager	Investigate shipping costs and their potential impact on margins across product categories.
Head of Customer Support	Understand late-delivery patterns and determine whether problems are concentrated or widespread.
Company Leadership	Obtain a unified view of seller value, customer satisfaction, delivery performance, and business risk.

## 📊 Analytical Reports

The project is divided into four detailed analytical reports.

### Report 1 — Customer Value & Seller Performance

Business Problem: The leadership team wants to identify our most valuable repeat customers and understand which 
sellers are driving that value. Right now, we don't know who our loyal customers are, which sellers they keep 
coming back to, or how satisfied they are with those purchases. Build a report that shows, for every customer 
who has placed 3 or more orders: their customer ID and city, the seller they buy from most often, their top 3 
highest-value orders, and their average review score (customers who haven't left a review should still appear, just marked accordingly).

Business Use: Marketing can use this to build a loyalty/retention campaign targeting high-value customers, and 
Seller Operations can identify which sellers are consistently winning repeat business — and which top-spend 
customers are quietly unhappy despite spending a lot.

👥 Stakeholder

Marketing & Sales / Seller Operations

##📄 Detailed Report : 

[Report 1 — Customer Value & Seller Performance](Reports/Report_1_Detailed.md)  

### Report 2: Product Category Performance & Shipping Cost Risk

Business Problem: Finance has noticed shipping costs eating into margins on certain products but doesn't know 
which categories are the problem. Build a report showing, for each product category (in English, not the raw 
Portuguese code): total number of orders, average product price, average freight cost, and freight cost as a 
percentage of price. Flag any category where freight regularly exceeds 30% of the product price.

Business Use: This tells Finance and the Pricing team exactly which categories need a shipping policy change — 
either a price adjustment, a freight subsidy cap, or excluding them from free-shipping promotions.

👥 Stakeholder

Finance, Pricing Team

##📄 Detailed Report :

[Report 2 — Product Category Performance & Shipping Cost Risk](Reports/Report_2_Detailed.md)

### Report 3: Delivery Performance by Region

Business Problem: Customer support has been getting complaints about late deliveries, but no one has confirmed if 
this is a regional/logistics problem or isolated incidents. Build a report showing, by customer state: total orders, 
average delivery time (purchase to actual delivery), percentage of orders delivered later than the estimated delivery 
date, and average review score for that state.

Business Use: Operations can use this to see exactly which states/regions have systemic delivery delays, and whether 
those delays are actually hurting review scores — justifying a logistics or courier-partner change in specific regions 
rather than a blanket fix.

👥 Stakeholder

Customer Support, Operations

##📄 Detailed Report :

[Report 3 — Delivery Performance by Region](Reports/Report_3_Detailed.md)

### Report 4 (Combined): Seller Risk Scorecard

Business Problem: Leadership wants a single scorecard to decide which sellers to keep promoting on the platform and 
which need a performance review or removal. Build a report that combines delivery performance, customer satisfaction, 
and sales volume for each seller: total orders fulfilled, average review score, late delivery rate, and total revenue generated. 
Rank sellers by revenue, but flag any seller who is in the top 20% for revenue while also being in the bottom 20% for review
score or having a late delivery rate above the platform average — these are high-risk sellers driving revenue but damaging customer trust.

Business Use: This gives leadership a single, ranked list to act on — reward top sellers who are also well-reviewed, and 
flag high-revenue-but-risky sellers for an urgent operational review before they damage the brand further.

👥 Stakeholder

Leadership, Seller Operations

##📄 Detailed Report :

[Report 4 — Seller Risk Scorecard](Reports/Report_4_Detailed.md)

## 📦Dataset : Brazilian E-Commerce Public Dataset by Olist

The dataset used in this project is publicly available on Kaggle and contains
information about customers, orders, order items, products, sellers, reviews,
payments, and related e-commerce transactions.

[View Dataset on Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

## Tools & Technologies

- **Oracle SQL** – Data extraction, transformation, aggregation, joins, CTEs, window functions, and business analysis
- **Git & GitHub** – Version control, project documentation, and portfolio management
- **Draw.io** – Data relationship and pipeline documentation

## SQL Methodology

The analysis follows a structured SQL workflow:

1. **Data Validation** – Filter and prepare relevant records for analysis.
2. **Data Integration** – Join related tables using customer, order, product, and seller keys.
3. **Data Transformation** – Use CTEs to break complex business logic into manageable steps.
4. **Aggregation** – Calculate order counts, revenue, freight costs, delivery times, review scores, and other business metrics.
5. **Window Functions** – Identify top sellers, highest-value orders, revenue rankings, and risk groups.
6. **Business Rules** – Apply defined thresholds and conditions to identify shipping-cost and seller-performance risks.
7. **Final Reporting** – Combine the transformed datasets into four business-focused reports.

## Project Structure

```text
Olist-SQL-Capstone/
│
├── README.md
│
├── Olist_Capstone_Reports.sql
│
└── Reports/
    ├── Report_1_Detailed.md
    ├── Report_2_Detailed.md
    ├── Report_3_Detailed.md
    └── Report_4_Detailed.md
```
## 💻 SQL Queries

The complete Oracle SQL implementation for all four analytical reports is available below.




