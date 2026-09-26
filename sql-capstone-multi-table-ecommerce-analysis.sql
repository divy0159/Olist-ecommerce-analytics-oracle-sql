----------------------------------------------------------------------------------------------------------------------------------
---------------------------------Olist 360: Seller, Customer & Delivery Performance Analytics-------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------

--Olist, a growing Brazilian e-commerce marketplace connecting third-party sellers with customers nationwide, 
--has been experiencing declining customer retention and rising customer complaints, but leadership lacks the 
--data-driven visibility to understand why. The Marketing and Sales Director wants to identify the company's most 
--valuable repeat customers, understand which sellers those customers keep returning to, and determine whether those 
--customers are actually satisfied, so that retention and loyalty campaigns can be properly targeted instead of guessed at. 
--At the same time, the Finance Manager has noticed shrinking margins and suspects that shipping costs on certain product 
--categories are quietly eating into profitability, but has no concrete evidence to justify a pricing or shipping policy change. 
--Simultaneously, the Head of Customer Support has been fielding a growing number of complaints about late 
--deliveries and needs to know whether this is a systemic regional logistics failure or a handful of isolated 
--incidents before escalating the issue to Operations. Finally, company leadership wants a single, unified view that 
--ties all of this together — one scorecard that reveals which sellers are genuinely valuable to the business versus which 
--sellers are generating high revenue while simultaneously damaging customer trust through poor delivery performance and low 
--satisfaction, so that seller partnerships can be reviewed, rewarded, or revoked based on evidence rather than assumption.

----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
--Report 1: Customer Value & Seller Performance
------------------------------------------------------------------------------------------------------------------------------------------------
--Business Problem: The leadership team wants to identify our most valuable repeat customers and understand which 
--sellers are driving that value. Right now, we don't know who our loyal customers are, which sellers they keep 
--coming back to, or how satisfied they are with those purchases. Build a report that shows, for every customer 
--who has placed 3 or more orders: their customer ID and city, the seller they buy from most often, their top 3 
--highest-value orders, and their average review score (customers who haven't left a review should still appear, just marked accordingly).

--Business Use: Marketing can use this to build a loyalty/retention campaign targeting high-value customers, and 
--Seller Operations can identify which sellers are consistently winning repeat business — and which top-spend 
--customers are quietly unhappy despite spending a lot.

With valid_orders as (
    select * from orders1 where 
    order_status  not in ('unavailable','cancelled')
    ),

customer_rec as (
    select c.customer_unique_id ,max(customer_city) as customer_city ,count(distinct vo.order_id) as total_orders  
    from 
    customers c 
    join valid_orders vo
    on c.customer_id = vo.customer_id 
    group by c.customer_unique_id
    having count(distinct vo.order_id) >= 3
    order by total_orders DESC),

top_sellers as (
select customer_unique_id ,seller_id ,orders 
from (
    select c.customer_unique_id , oi.seller_id ,count(distinct oi.order_id ) as orders ,
    row_number() over(partition by customer_unique_id order by count(distinct oi.order_id) desc , oi.seller_id ) as rno
    from customers c 
    join valid_orders vo
    on c.customer_id = vo.customer_id 
    join order_items oi 
    on vo.order_id = oi.order_id 
    group by customer_unique_id , oi.seller_id
    ) t 
    where rno = 1 
    order by orders desc),

top3_high_prices as (
select customer_unique_id, order_id, prices, rn as rank_of_highest_price 
from (
         select c.customer_unique_id, oi.order_id, 
         sum(price + freight_value) as prices,
         row_number() over(partition by customer_unique_id 
         order by sum(price + freight_value) desc ,oi.order_id 
    ) as rn
           
    from customers c 
    join valid_orders vo 
    on c.customer_id = vo.customer_id
    join order_items oi 
    on vo.order_id = oi.order_id 
    group by customer_unique_id, oi.order_id
) t 
where rn <= 3
order by customer_unique_id, rn),

avg_review as (
    SELECT customer_unique_id ,coalesce(cast (round(avg(review_score),2) as varchar2(20)) ,'No Review' )  as final_review  
    FROM customers c 
    left join valid_orders vo 
    on c.customer_id = vo.customer_id 
    left join order_reviews orr 
    on vo.order_id = orr.order_id 
    group by customer_unique_id)

select cr.customer_unique_id, 
       cr.customer_city, 
       cr.total_orders, 
       ts.seller_id,
       ts.orders as top_seller_order_count,
       max(case when thp.rank_of_highest_price = 1 then thp.order_id end) as top_order_1,
       max(case when thp.rank_of_highest_price = 1 then thp.prices end)   as top_order_1_value,
       max(case when thp.rank_of_highest_price = 2 then thp.order_id end) as top_order_2,
       max(case when thp.rank_of_highest_price = 2 then thp.prices end)   as top_order_2_value,
       max(case when thp.rank_of_highest_price = 3 then thp.order_id end) as top_order_3,
       max(case when thp.rank_of_highest_price = 3 then thp.prices end)   as top_order_3_value,
       ar.final_review
    from customer_rec cr 
    left join top_sellers ts 
    on cr.customer_unique_id = ts.customer_unique_id 
    left join top3_high_prices thp 
    on cr.customer_unique_id = thp.customer_unique_id 
    left join avg_review ar 
    on cr.customer_unique_id = ar.customer_unique_id 
    group by cr.customer_unique_id, cr.customer_city, cr.total_orders, ts.seller_id, ts.orders,ar.final_review
    order by cr.total_orders DESC;

-----------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------

--Report 2: Product Category Performance & Shipping Cost Risk
------------------------------------------------------------------------------------------------------------------------------------------------
--Business Problem: Finance has noticed shipping costs eating into margins on certain products but doesn't know 
--which categories are the problem. Build a report showing, for each product category (in English, not the raw 
--Portuguese code): total number of orders, average product price, average freight cost, and freight cost as a 
--percentage of price. Flag any category where freight regularly exceeds 30% of the product price.

--Business Use: This tells Finance and the Pricing team exactly which categories need a shipping policy change — 
--either a price adjustment, a freight subsidy cap, or excluding them from free-shipping promotions.


with prod_cat as(
        select product_category_name_english , 
        product_id 
        from 
        product_category pc 
        join products1 p1 
        on 
        pc.product_category_name = p1.product_category_name ) ,
        
freight_cost as (
    select product_id,
    avg(price) as avg_price,
    avg(freight_value) as avg_freight,
    count(distinct order_id) as order_count,
    round((avg(freight_value)/ avg(price))*100 ,1) as Freight_cos,
    case
    when (avg(freight_value)/ avg(price)) > 0.30 
    then 1
    else 0
    end as Freight_cat
    from 
    order_items
    group by product_id
     )
    select 
    concat(sum(fc.order_count), ' orders') as Orders_placed,
    pt.product_category_name_english as category,
    round(avg(fc.avg_price),1) as Average_price_of_product,
    round(avg(fc.avg_freight),1) as Average_freight_value,
    concat(round(avg(fc.Freight_cos),1),'%') as Freight_cost,
    round(100.0*sum(fc.Freight_cat)/count(*), 1) as Pct_products_over_30,

    Case
    when (100.0*sum(fc.Freight_cat)/count(*)) >= 50
    then '⚠'
    else 'Ok'
    end as Freight_flag
from 
    freight_cost fc
join
    prod_cat pt
on 
    pt.product_id = fc.product_id
group by pt.product_category_name_english
order by Pct_products_over_30 desc;

----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------

--Report 3: Delivery Performance by Region
-----------------------------------------------------------------------------------------------------------------------------------------------
--Business Problem: Customer support has been getting complaints about late deliveries, but no one has confirmed if 
--this is a regional/logistics problem or isolated incidents. Build a report showing, by customer state: total orders, 
--average delivery time (purchase to actual delivery), percentage of orders delivered later than the estimated delivery 
--date, and average review score for that state.

--Business Use: Operations can use this to see exactly which states/regions have systemic delivery delays, and whether 
--those delays are actually hurting review scores — justifying a logistics or courier-partner change in specific regions 
--rather than a blanket fix.

with state_ordersplaced as(

    select c.customer_state ,count(distinct o1.order_id) as  orders_placed 
    from customers c 
    join 
    orders1 o1 
    on c.customer_id = o1.customer_id 
    group by customer_state
    order by customer_state
    ) ,
deli_days as (
    select c.customer_state, round(avg((order_delivered_customer_date) - (order_purchase_timestamp)),1) as avg_days 
    from orders1 o1 
    join customers c
    on o1.customer_id = c.customer_id
    where order_delivered_customer_date is not null
    group by customer_state 
    order by customer_state
    ) , 
avg_rev as (
    select c.customer_state, round(avg(review_score),2) as Avg_review 
    from order_reviews ors
    join orders1 o1
    on ors.order_id = o1.order_id 
    join customers c
    on c.customer_id = o1.customer_id 
    where order_delivered_customer_date is not null
    group by customer_state 
    order by customer_state
    ) ,
est_del as(
    select c.customer_state,
    round(100.0 *sum(case when
    order_delivered_customer_date > order_estimated_delivery_date 
    then 1
    else 0
    end )/count(*),1) as order_pct
    from 
    orders1  o1
    join customers c
    on c.customer_id  = o1.customer_id
    where order_delivered_customer_date is not null
    group by customer_state 
    order by customer_state
    )
    
    select so.customer_state, so.orders_placed ,di.avg_days , ar.Avg_review ,es.order_pct
    from state_ordersplaced so
    left join deli_days di
    on so.customer_state = di.customer_state
    left join avg_rev ar
    on so.customer_state = ar.customer_state 
    left join est_del es
    on so.customer_state = es.customer_state
    order by customer_state;

-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------

--Report 4 (Combined): Seller Risk Scorecard
-----------------------------------------------------------------------------------------------------------------------------------------------

--Business Problem: Leadership wants a single scorecard to decide which sellers to keep promoting on the platform and 
--which need a performance review or removal. Build a report that combines delivery performance, customer satisfaction, 
--and sales volume for each seller: total orders fulfilled, average review score, late delivery rate, and total revenue generated. 
--Rank sellers by revenue, but flag any seller who is in the top 20% for revenue while also being in the bottom 20% for review
--score or having a late delivery rate above the platform average — these are high-risk sellers driving revenue but damaging customer trust.

--Business Use: This gives leadership a single, ranked list to act on — reward top sellers who are also well-reviewed, and 
--flag high-revenue-but-risky sellers for an urgent operational review before they damage the brand further.


with seller_orders_revenue as (
    select oi.seller_id,
           count(distinct oi.order_id) as orders_fulfilled,
           sum(oi.price) as total_revenue
    from order_items oi
    group by oi.seller_id
),
seller_late as (
    select oi.seller_id,
           round(100.0 * sum(case when o1.order_delivered_customer_date > o1.order_estimated_delivery_date 
                                   then 1 else 0 end) / count(*), 1) as late_pct
    from order_items oi
    join orders1 o1
      on oi.order_id = o1.order_id
    where o1.order_delivered_customer_date is not null
    group by oi.seller_id
),
seller_reviews as (
    select oi.seller_id,
           round(avg(ors.review_score), 2) as avg_review
    from order_items oi
    join order_reviews ors
      on oi.order_id = ors.order_id
    join orders1 o1
      on oi.order_id = o1.order_id
    where o1.order_delivered_customer_date is not null
    group by oi.seller_id
),
platform_avg_late as (
    select round(100.0 * sum(case when order_delivered_customer_date > order_estimated_delivery_date 
                                   then 1 else 0 end) / count(*), 1) as platform_late_pct
    from orders1
    where order_delivered_customer_date is not null
),
seller_combined as (
    select sr.seller_id,
           sr.orders_fulfilled,
           sr.total_revenue,
           sl.late_pct,
           srv.avg_review
    from seller_orders_revenue sr
    left join seller_late sl
      on sr.seller_id = sl.seller_id
    left join seller_reviews srv
      on sr.seller_id = srv.seller_id
),
seller_ranked as (
    select sc.*,
           ntile(5) over (order by sc.total_revenue desc) as revenue_bucket,
           ntile(5) over (order by sc.avg_review asc nulls first) as review_bucket
    from seller_combined sc
)
select sr.seller_id,
       sr.orders_fulfilled,
       sr.total_revenue,
       sr.avg_review,
       sr.late_pct,
       pal.platform_late_pct,
       rank() over (order by sr.total_revenue desc) as revenue_rank,
       case when sr.revenue_bucket = 1
                 and (sr.review_bucket = 1
                      or sr.late_pct > pal.platform_late_pct)
            then 'High Risk'
            else 'OK'
       end as risk_flag
from seller_ranked sr
cross join platform_avg_late pal
order by sr.total_revenue desc;

---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------

--TESTING--
----------------------------------------------------------------------------------------------------------------------------------------------
--Build a report that shows, for every customer 
--who has placed 3 or more orders ,their customer ID and city,
select c.customer_unique_id ,max(customer_city) as customer_city ,count(distinct o1.order_id) as count_of_orders  from 
customers c join orders1 o1 on c.customer_id = o1.customer_id 
group by c.customer_unique_id
having count(distinct o1.order_id) >= 3
order by count_of_orders DESC;


--the seller they buy from most often

select customer_unique_id ,seller_id ,orders from (select c.customer_unique_id , oi.seller_id ,count(distinct oi.order_id ) as orders ,
row_number() over(partition by customer_unique_id order by count(distinct oi.order_id) desc) as rno
from customers c join orders1 o1 on c.customer_id = o1.customer_id 
join order_items oi on o1.order_id = oi.order_id group by customer_unique_id , oi.seller_id)
t where rno = 1 
order by orders desc;


--their top 3 
--highest-value orders

select customer_unique_id, order_id, prices, rn from (
    select c.customer_unique_id, oi.order_id, 
           sum(price + freight_value) as prices,
           count(*) over(partition by customer_unique_id) as ct,
           row_number() over(partition by customer_unique_id order by sum(price + freight_value) desc) as rn
           
    from customers c 
    join orders1 ol on c.customer_id = ol.customer_id
    join order_items oi on ol.order_id = oi.order_id 
    group by customer_unique_id, oi.order_id
) t 
where 
ct >=3 and 
rn <= 3 and customer_unique_id = '06a52782a04f0086d16b9c22d0e29438'
order by customer_unique_id, rn;

--their average review score (customers who haven't left a review should still appear, just marked accordingly).

SELECT customer_unique_id ,coalesce(cast (round(avg(review_score),2) as varchar2(20)) ,'No Review' )  as final_review  FROM customers c 
left join orders1 o1 on c.customer_id = o1.customer_id 
left join order_reviews orr on o1.order_id = orr.order_id group by customer_unique_id;

select * from orders1 where order_status  like '%unavailable%' or order_status   like '%cancelled%';

