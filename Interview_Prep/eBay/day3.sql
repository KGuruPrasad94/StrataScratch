-- 📘 SQL Interview Practice Breakdown (eBay - Data Analyst Role)

-- 🗓️ Day 3 Questions — eBay Data Analyst SQL Mock

-- 🔹 Question 7 – Medium: Average Time Between Orders
-- ✅ Question:
-- Calculate the average number of days between orders for each customer. Only include customers who have placed at least two orders.
-- 💃 Table + Schema:
-- orders(order_id INT, customer_id INT, order_date DATE)

-- ❌ User’s Attempt:
-- (Write your solution below this line)

with cust as (
  select customer_id, count(order_id) orders, 
         min(order_date) first_order, max(order_date) last_order,
         datediff(max(order_date), min(order_date)) as days_diff
  from orders
  group by 1
  having count(order_id) >= 1
)

select customer_id, days_diff/orders as avg_days
from cust 
group by 1

-- 💡 Feedback:
-- You correctly calculated the difference between the max and min order dates, but:
-- 1. You used `having count(order_id) >= 1`, which includes customers with just 1 order. Should be `>= 2`.
-- 2. Your formula `days_diff/orders` is incorrect. For n orders, there are (n-1) intervals between them.
-- 3. `group by` in the outer query is unnecessary since it's already grouped inside the CTE.

-- ✅ Corrected version:
with cust as (
  select customer_id, count(order_id) as orders, 
         datediff(max(order_date), min(order_date)) as days_diff
  from orders
  group by customer_id
  having count(order_id) >= 2
)
select customer_id, round(days_diff / (orders - 1), 2) as avg_days_between_orders
from cust;

-- 🧠 Explanation:
-- We only include customers with 2+ orders. The number of intervals is (orders - 1),
-- and `datediff(max, min)` gives the total span of those orders. Dividing gives average gap.

-- 🔹 Question 8 – Medium: Funnel Conversion Rates
-- ✅ Question:
-- Given a user events table, calculate the conversion rate from 'view' → 'cart' → 'purchase' for each user.
-- 💃 Table + Schema:
-- user_events(user_id INT, event_type VARCHAR, event_time DATETIME)

-- ❌ User’s Attempt:
-- (Write your solution below this line)

-- Get each user's count of views, carts, and purchases
select user_id, 
       carts / nullif(views, 0) as view_to_cart_rate, 
       purchases / nullif(carts, 0) as cart_to_purchase_rate
from (
  select user_id,
         sum(case when event_type = 'view' then 1 else 0 end) as views,
         sum(case when event_type = 'cart' then 1 else 0 end) as carts,
         sum(case when event_type = 'purchase' then 1 else 0 end) as purchases
  from user_events
  group by user_id
) as event_summary;

-- 💡 Feedback:
-- Good approach to pivot event types into counts.
-- 1. You correctly used `nullif` to prevent divide-by-zero errors.
-- 2. Aliased the subquery for clean structure.
-- 3. The logic reflects a solid per-user funnel conversion pattern.

-- 🧠 Explanation:
-- `nullif(views, 0)` prevents divide-by-zero errors when calculating conversion rates.
-- This shows per-user conversion funnel from views → carts → purchases.

-- 🔴 Question 9 – Hard: First-to-Second Order Conversion Rate
-- ✅ Question:
-- Determine the percentage of customers who placed a second order within 30 days of their first order.
-- 💃 Table + Schema:
-- orders(order_id INT, customer_id INT, order_date DATE)

-- ❌ User’s Attempt:
-- (Write your solution below this line)

with first_orders as (
  select customer_id, order_id, min(order_date) first_order
  from orders
  group by 1
)

select 
  (count(distinct o.customer_id) / (select count(distinct f.customer_id) from first_orders)) as Order_Conversion_Rate
from first_orders f
left join orders o
  on f.customer_id = o.customer_id
  and datediff(o.order_date, first_order) < 30
  and o.order_date > first_order;

-- 💡 Feedback:
-- 1. Your main logic is mostly correct in checking second orders within 30 days.
-- 2. `o.order_date > first_order` is present – good.
-- 3. Denominator is calculated correctly.
-- 4. Could be cleaned up by separating the second orders in a CTE.
-- 5. Small mistake: `group by 1` in `first_orders` should be `group by customer_id` to be clear.

-- ✅ Corrected version:
with first_orders as (
  select customer_id, min(order_date) as first_order
  from orders
  group by customer_id
),
second_orders as (
  select o.customer_id
  from orders o
  join first_orders f
    on o.customer_id = f.customer_id
   and o.order_date > f.first_order
   and datediff(o.order_date, f.first_order) <= 30
  group by o.customer_id
)
select round(count(distinct s.customer_id) * 100.0 / count(distinct f.customer_id), 2) as Order_Conversion_Rate
from first_orders f
left join second_orders s
  on f.customer_id = s.customer_id;

-- 🧠 Explanation:
-- We find each customer's first order and check if any later order was placed within 30 days.
-- Final conversion rate is distinct second-order customers divided by total unique customers.


