-- 🗓️ Day 2 Questions — eBay SQL Mock Interview

-- 🔹 Question 4 – Medium: Daily Orders vs. Average
-- ✅ Question:
-- Find the days where daily orders exceeded the average daily orders.

-- 💃 Table + Schema:
-- Table: orders
-- Columns: order_id (INT), customer_id (INT), order_date (DATE)

-- ✅ Corrected Version:
SELECT order_date, COUNT(*) AS daily_orders
FROM orders
GROUP BY order_date
HAVING COUNT(*) > (
  SELECT AVG(daily_count)
  FROM (
    SELECT COUNT(*) AS daily_count
    FROM orders
    GROUP BY order_date
  ) AS daily_counts
);

-- 🧠 Explanation:
-- First calculates average across all days, compares each day to it.

-- 🔹 Question 5 – Medium: Product Reorder Rate
-- ✅ Question:
-- For each product, calculate how often customers reorder it (i.e., purchase it again).

-- 💃 Table + Schema:
-- Table: order_details
-- Columns: order_id (INT), customer_id (INT), product_id (INT), order_date (DATE)

-- ❌ User’s Attempt:
WITH first_order AS (
  SELECT order_id, customer_id, product_id, MIN(order_date) AS first_order_date
  FROM order_details
  GROUP BY 1,2,3
),

reorders AS (
  SELECT f.product_id, COUNT(DISTINCT f.customer_id) AS orders,
         SUM(CASE WHEN o.order_date IS NOT NULL THEN 1 ELSE 0 END) AS reorder_count
  FROM first_order f
  LEFT JOIN order_details o
    ON f.product_id = o.product_id
    AND f.customer_id = o.customer_id
    AND o.order_date > f.first_order_date
  GROUP BY f.product_id
)

SELECT product_id,
       ROUND(reorder_count / orders, 2) AS reorder_rate
FROM reorders;

-- 💡 Feedback:
-- 1. Grouping doesn't match the join logic properly.
-- 2. Misalignment between how customers are tracked vs. counted.

-- ✅ Corrected Version:
WITH first_order AS (
  SELECT customer_id, product_id, MIN(order_date) AS first_order_date
  FROM order_details
  GROUP BY customer_id, product_id
),

reorders AS (
  SELECT f.product_id,
         COUNT(DISTINCT f.customer_id) AS total_customers,
         COUNT(DISTINCT CASE WHEN o.order_id IS NOT NULL THEN f.customer_id END) AS reordering_customers
  FROM first_order f
  LEFT JOIN order_details o
    ON f.customer_id = o.customer_id
   AND f.product_id = o.product_id
   AND o.order_date > f.first_order_date
  GROUP BY f.product_id
)

SELECT product_id,
       ROUND(reordering_customers / total_customers, 2) AS reorder_rate
FROM reorders;

-- 🧠 Explanation:
-- Compares customers who reordered to total customers who ever ordered the product.

-- 🔹 Question 6 – Hard: Active-to-Inactive Conversion Rate
-- ✅ Question:
-- Calculate what % of users were active last month but inactive this month.

-- 💃 Table + Schema:
-- Table: orders
-- Columns: customer_id (INT), order_date (DATE)

-- ❌ User's Attempt:
WITH last_month AS (
  SELECT customer_id
  FROM orders
  WHERE MONTH(order_date) = MONTH(CURRENT_DATE) - 1 
  GROUP BY customer_id
),

current_month AS (
  SELECT customer_id
  FROM orders
  WHERE MONTH(order_date) = MONTH(CURRENT_DATE)
  GROUP BY customer_id
)

SELECT COUNT(DISTINCT l.customer_id) / COUNT(*)
FROM last_month l
LEFT JOIN current_month c 
  ON l.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 💡 Feedback:
-- 1. Lacks YEAR handling — MONTH alone can compare Jan of one year to Dec of another.
-- 2. Final SELECT expression was invalid — COUNT DISTINCT and subqueries misplaced.

-- ✅ Corrected Version:
WITH last_month AS (
  SELECT DISTINCT customer_id
  FROM orders
  WHERE DATE_FORMAT(order_date, '%Y-%m') = DATE_FORMAT(DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH), '%Y-%m')
),

this_month AS (
  SELECT DISTINCT customer_id
  FROM orders
  WHERE DATE_FORMAT(order_date, '%Y-%m') = DATE_FORMAT(CURRENT_DATE, '%Y-%m')
)

SELECT ROUND(COUNT(l.customer_id) / (SELECT COUNT(*) FROM last_month), 2) AS churn_rate
FROM last_month l
LEFT JOIN this_month t ON l.customer_id = t.customer_id
WHERE t.customer_id IS NULL;

-- 🧠 Explanation:
-- Identifies users who dropped out this month despite activity last month.
