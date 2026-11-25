-- ==========================================================================================================================================
-- 05_regional_markets.sql
--   5.1 METRICS BY CUSTOMER STATE (ORDERS, REVENUE, AVG PRICE, AVG FREIGHT, DELIVERY TIME, AVG REVIEW SCORE)
--   5.2 METRICS BY CUSTOMER CITY (ORDERS, REVENUE, AVG PRICE, AVG FREIGHT, DELIVERY TIME, AVG REVIEW SCORE)
--   5.3 TOP 10 STATES BY ITEMS AND THEIR MOST POPULAR CATEGORY
--   5.4 TOP 10 CITIES BY ITEMS AND THEIR MOST POPULAR CATEGORY

-- ==========================================================================================================================================
-- 5.1 METRICS FOR CUSTOMER STATE ORDERED BY REVENUE (ORDERS, REVENUE, AVG PRICE, AVG FREIGHT, DELIVERY TIME, AVG REVIEW SCORE)

SELECT *
FROM `olist-pricing-analysis.olist.big_table`;

SELECT 
  customer_state, 
  ROUND(SUM(price), 2) AS revenue,
  ROUND(AVG(price),2) AS average_price, 
  ROUND(AVG(freight_value), 2) AS average_freight, 
  ROUND(AVG(delivery_days), 2) AS average_delivery_days, 
  ROUND(AVG(review_score), 2) AS average_review_score
FROM `olist-pricing-analysis.olist.big_table`
GROUP BY customer_state
ORDER BY revenue DESC;

-- ==========================================================================================================================================
-- 5.2 METRICS FOR CUSTOMER CITY ORDERED BY REVENUE (ORDERS, REVENUE, AVG PRICE, AVG FREIGHT, DELIVERY TIME, AVG REVIEW SCORE)

SELECT
  customer_city,
  customer_state, 
  ROUND(SUM(price), 2) AS revenue,
  ROUND(AVG(price),2) AS average_price, 
  ROUND(AVG(freight_value), 2) AS average_freight, 
  ROUND(AVG(delivery_days), 2) AS average_delivery_days, 
  ROUND(AVG(review_score), 2) AS average_review_score
FROM `olist-pricing-analysis.olist.big_table`
GROUP BY customer_city, customer_state
ORDER BY revenue DESC
LIMIT 20;

-- ==========================================================================================================================================
-- 5.3 TOP 10 STATES BY ITEMS AND THEIR MOST POPULAR CATEGORY

SELECT customer_state, category, COUNT(*) AS items_sold
FROM `olist-pricing-analysis.olist.big_table`
GROUP BY customer_state, category;

WITH categories_and_states AS (
  SELECT customer_state, category, COUNT(*) AS items_sold
  FROM `olist-pricing-analysis.olist.big_table`
  GROUP BY customer_state, category)
SELECT customer_state, category, items_sold 
FROM categories_and_states
QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_state ORDER BY items_sold DESC) = 1
ORDER BY items_sold DESC
LIMIT 10;

-- ==========================================================================================================================================
-- 5.4 TOP 10 CITIES BY ITEMS AND THEIR MOST POPULAR CATEGORY

WITH categories_and_cities AS (
  SELECT customer_city, category, COUNT(*) AS items_sold
  FROM `olist-pricing-analysis.olist.big_table`
  GROUP BY customer_city, category)
SELECT customer_city, category, items_sold 
FROM categories_and_cities
QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_city ORDER BY items_sold DESC) = 1
ORDER BY items_sold DESC
LIMIT 10;

