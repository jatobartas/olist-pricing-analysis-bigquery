-- ==========================================================================================================================================
-- 05_regional_markets.sql
-- Project : Price Position and Market Analysis of an E-commerce Marketplace
-- Purpose : Compare regions (customer states) using the base view big_table.
--
-- Contents
--   5.1 Metrics by customer state
--   5.2 Metrics by customer city
-- ==========================================================================================================================================
-- 5.1 METRICS BY CUSTOMER STATE
-- Orders, revenue, average price, average freight, delivery time and review score per state.
-- States are ordered by revenue.

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
-- 5.2 METRICS BY CUSTOMER CITY
-- Orders, revenue, average price, average freight, delivery time and review score per city.
-- Cities are ordered by revenue.

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
-- 5.3 MOST POPULAR CATEGORY IN EACH STATE
-- Category with the highest number of items sold in each customer state.
-- States are ordered by items sold in their top category.

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
-- 5.4 MOST POPULAR CATEGORY IN THE LARGEST CITIES
-- Category with the highest number of items sold in each city.
-- Cities are ordered by items sold in their top category; the top 10 are shown.

WITH categories_and_cities AS (
  SELECT customer_city, category, COUNT(*) AS items_sold
  FROM `olist-pricing-analysis.olist.big_table`
  GROUP BY customer_city, category)
SELECT customer_city, category, items_sold 
FROM categories_and_cities
QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_city ORDER BY items_sold DESC) = 1
ORDER BY items_sold DESC
LIMIT 10;

