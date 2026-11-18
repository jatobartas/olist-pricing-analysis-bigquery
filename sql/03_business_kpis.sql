-- ===========================================================================================================================================
-- 03_business_kpis.sql
-- Project : Price Position and Market Analysis of an E-commerce Marketplace
-- Purpose : Business KPIs calculated from the base view big_table (delivered order items only).
-- Contents
--   3.1 Overall KPIs
--   3.2 Monthly trend
--   3.3 Top 10 categories

--===========================================================================================================================================
-- 3.1 OVERALL KPIs
-- Revenue = sum of item prices (freight not included).
-- Average order value = revenue / number of distinct orders.
-- Customers are counted with customer_unique_id (a real customer);
-- customer_id is assigned per order.
-- AVG ignores NULL values (missing delivery days and review scores).

SELECT *
FROM `olist-pricing-analysis.olist.big_table`
LIMIT 20;

SELECT COUNT(*) AS items_sold, 
COUNT(DISTINCT(order_id)) AS orders,
COUNT(DISTINCT(product_id)) AS products,
COUNT(DISTINCT(seller_id)) AS sellers,
COUNT(DISTINCT(customer_unique_id)) AS customers,
ROUND(SUM(price), 3) AS revenue,
ROUND(SUM(price)/1000000, 3) AS mln_revenue,
ROUND(SUM(freight_value), 2) AS total_freight,
ROUND(SUM(price)/COUNT(DISTINCT(order_id)), 2) AS average_order_value,
ROUND(AVG(price), 2) AS avg_price,
APPROX_QUANTILES(price, 100)[OFFSET (50)] AS median_item_price,
APPROX_QUANTILES(price, 100)[OFFSET (99)] AS ninetynine_percentil_price,
ROUND(AVG(delivery_days), 1) AS average_delivery_days,
ROUND(AVG(review_score), 2) AS average_review_score
FROM `olist-pricing-analysis.olist.big_table`;

-- ==========================================================================================================================================
-- 3.2 MONTHLY TREND
-- Orders, items, revenue and average order value per purchase month.
-- Used to see growth and seasonality and to check whether the first and last months of the data are too standing out to be shown in trends.

SELECT purchase_month,
COUNT(*) AS items_sold, 
ROUND(SUM(price), 2) AS revenue,
ROUND(SUM(price)/COUNT(DISTINCT(order_id)), 2) AS average_order_value
FROM `olist-pricing-analysis.olist.big_table`
GROUP BY purchase_month
ORDER BY purchase_month;

SELECT MAX(revenue) AS max_revenue
FROM
(SELECT purchase_month, ROUND(SUM(price), 2) AS revenue
FROM `olist-pricing-analysis.olist.big_table`
GROUP BY purchase_month
ORDER BY revenue);

--==========================================================================================================================================
-- 3.3 TOP 10 CATEGORIES
-- Revenue, items sold, average and median price and share of total revenue for the 10 categories with the highest revenue.
-- Category "unknown" (products without category) is kept in the totals.

SELECT *
FROM `olist-pricing-analysis.olist.big_table`
LIMIT 20;

SELECT 
  category,  
  ROUND(SUM(price),2) AS revenue,
  COUNT(*) AS items_sold,
  ROUND(AVG(price), 2) AS average_price,
  APPROX_QUANTILES(price, 100)[OFFSET (50)] AS median_price
FROM `olist-pricing-analysis.olist.big_table`
GROUP BY category
ORDER BY revenue DESC
LIMIT 10;

--============================================================================================================================================

