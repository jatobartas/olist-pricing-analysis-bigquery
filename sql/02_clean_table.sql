-- ===========================================================================================================================================
-- 02_clean_table.sql
-- Project : Price Position and Market Analysis of an E-commerce Marketplace
-- Data    : Olist Brazilian E-Commerce dataset (Kaggle), loaded to BigQuery
--           as `olist-pricing-analysis.olist`
-- Purpose : Build the base view used by all further analyses(one row per order item, delivered orders only).
-- Contents
--   2.1 View design
--   2.2 Reviews aggregated to one row per order (view reviews_per_order)
--   2.3 Base view clean_order_items

--===========================================================================================================================================
-- 2.1 VIEW DESIGN (no SQL to run)

-- Grain: one row per order item (order_items), because prices and freight values are stored there. Only tables that do not multiply the number of rows are joined.
--
--   orders               INNER JOIN on order_id    status, dates; filters delivered orders
--   products             LEFT JOIN  on product_id  product category
--   category_translation LEFT JOIN  on category    English category name
--   customers            LEFT JOIN  on customer_id customer state
--   sellers              LEFT JOIN  on seller_id   seller state
--   reviews_per_order    LEFT JOIN  on order_id    review score (see 2.2)

----==========================================================================================================================================
-- 2.2 REVIEWS AGGREGATED TO ONE ROW PER ORDER
-- As from 1.1 CHECK OF DISTINCT KEYS, an order can have more than one review (99,224 rows for 98,673 orders), so reviews are averaged per order before joining;otherwise item rows would be duplicated.

CREATE OR REPLACE VIEW `olist-pricing-analysis.olist.reviews_per_order` AS
SELECT order_id, ROUND(AVG(review_score), 2) AS review_score
FROM `olist-pricing-analysis.olist.order_reviews`
GROUP BY order_id;

-- ===========================================================================================================================================
-- 2.3 BASE VIEW clean_order_items
-- Creation of one big table with everything inside 
-- One row - one order item
-- INNER JOIN keeps only matching rows; LEFT JOIN keeps every item even when the related row is missing.
-- COALESCE takes the first english name that isn't null, if it's null it takes the portugese name, and if this one is null, it returns 'unknown'
-- SAFE_DIVIDE returns NULL instead of an error when dividing by zero.
-- TIMESTAMP_DIFF returns a difference in time between dates
-- WHERE (delivered orders only)

--one by one - first the order_items with orders
SELECT order_items.order_id, 
       order_items.seller_id, 
       order_items.price, 
       order_items.freight_value,
       orders.customer_id,
       DATE(orders.order_purchase_timestamp) AS purchase_date,
       DATE_TRUNC(DATE(orders.order_purchase_timestamp), MONTH) AS purchase_month,
       TIMESTAMP_DIFF(order_delivered_customer_date, Orders.order_purchase_timestamp, DAY) AS delivery_days,
       ROUND(SAFE_DIVIDE(order_items.freight_value, order_items.price),2) AS freight_share_of_price
FROM `olist-pricing-analysis.olist.order_items` AS order_items
INNER JOIN `olist-pricing-analysis.olist.orders` AS orders
ON order_items.order_id = orders.order_id;

--now customers
SELECT order_items.order_id, 
       order_items.seller_id, 
       order_items.price, 
       order_items.freight_value,
       orders.customer_id,
       DATE(orders.order_purchase_timestamp) AS purchase_date,
       DATE_TRUNC(DATE(orders.order_purchase_timestamp), MONTH) AS purchase_month,
       TIMESTAMP_DIFF(order_delivered_customer_date, Orders.order_purchase_timestamp, DAY) AS delivery_days,
       ROUND(SAFE_DIVIDE(order_items.freight_value, order_items.price),3) AS freight_share_of_price,
       customers.customer_unique_id,
       customers.customer_state,
       customers.customer_city
FROM `olist-pricing-analysis.olist.order_items` AS order_items
INNER JOIN `olist-pricing-analysis.olist.orders` AS orders
ON order_items.order_id = orders.order_id
LEFT JOIN `olist-pricing-analysis.olist.customers` AS customers
ON orders.customer_id = customers.customer_id;

--now sellers

SELECT order_items.order_id, 
       order_items.seller_id, 
       order_items.price, 
       order_items.freight_value,
       orders.customer_id,
       DATE(orders.order_purchase_timestamp) AS purchase_date,
       DATE_TRUNC(DATE(orders.order_purchase_timestamp), MONTH) AS purchase_month,
       TIMESTAMP_DIFF(order_delivered_customer_date, Orders.order_purchase_timestamp, DAY) AS delivery_days,
       ROUND(SAFE_DIVIDE(order_items.freight_value, order_items.price),3) AS freight_share_of_price,
       customers.customer_unique_id,
       customers.customer_state,
       customers.customer_city,
       sellers.seller_state,
       sellers.seller_city
FROM `olist-pricing-analysis.olist.order_items` AS order_items
INNER JOIN `olist-pricing-analysis.olist.orders` AS orders
ON order_items.order_id = orders.order_id
LEFT JOIN `olist-pricing-analysis.olist.customers` AS customers
ON orders.customer_id = customers.customer_id
LEFT JOIN `olist-pricing-analysis.olist.sellers` AS sellers
ON order_items.seller_id = sellers.seller_id;

--now reviews and products -> + category translation - ALL TOGETHER
-- big_table: one row per delivered order item, with category, states, review score and delivery metrics
CREATE OR REPLACE VIEW `olist-pricing-analysis.olist.big_table` AS
SELECT order_items.order_id,
       order_items.order_item_id,
       order_items.product_id,
       order_items.seller_id, 
       order_items.price, 
       order_items.freight_value,
       orders.customer_id,
       DATE(orders.order_purchase_timestamp) AS purchase_date,
       DATE_TRUNC(DATE(orders.order_purchase_timestamp), MONTH) AS purchase_month,
       TIMESTAMP_DIFF(orders.order_delivered_customer_date, orders.order_purchase_timestamp, DAY) AS delivery_days,
       ROUND(SAFE_DIVIDE(order_items.freight_value, order_items.price),3) AS freight_share_of_price,
       customers.customer_unique_id,
       customers.customer_state,
       customers.customer_city,
       sellers.seller_state,
       sellers.seller_city,
       reviews.review_score,
       products.product_category_name AS portuguese_category,
       COALESCE(category.product_category_name_english, NULLIF(products.product_category_name, ''), 'unknown') AS category
FROM `olist-pricing-analysis.olist.order_items` AS order_items
INNER JOIN `olist-pricing-analysis.olist.orders` AS orders
ON order_items.order_id = orders.order_id
LEFT JOIN `olist-pricing-analysis.olist.customers` AS customers
ON orders.customer_id = customers.customer_id
LEFT JOIN `olist-pricing-analysis.olist.sellers` AS sellers
ON order_items.seller_id = sellers.seller_id
LEFT JOIN `olist-pricing-analysis.olist.reviews_per_order` AS reviews
ON order_items.order_id = reviews.order_id
LEFT JOIN `olist-pricing-analysis.olist.products` AS products
ON order_items.product_id = products.product_id
LEFT JOIN `olist-pricing-analysis.olist.category_translation` AS category
ON products.product_category_name = category.product_category_name
WHERE orders.order_status = 'delivered';

--============================================================================================================================================
-- 2.4 VALIDATION
-- view rows must equal expected rows (no duplicated or lost items);
-- distinct item keys must equal view rows (key order_id + order_item_id is unique);
-- missing values show whether any join lost data.

SELECT 'How many rows' AS check_name, COUNT(*) AS value
FROM `olist-pricing-analysis.olist.big_table`
UNION ALL
SELECT "Expected rows (delivered)", COUNT(*)
FROM `olist-pricing-analysis.olist.big_table` AS big_table
INNER JOIN `olist-pricing-analysis.olist.orders` AS orders
ON big_table.order_id = orders.order_id
WHERE orders.order_status = 'delivered'
UNION ALL
SELECT "Distinct keys in the big table (order_id + order_item_id)", 
      COUNT(DISTINCT(CONCAT(order_id, '-', CAST(order_item_id AS STRING))))
FROM `olist-pricing-analysis.olist.big_table`
UNION ALL
SELECT "Missing customer state", COUNTIF(customer_state IS NULL)
FROM `olist-pricing-analysis.olist.big_table`
UNION ALL
SELECT "Missing customer city", COUNTIF(customer_city IS NULL)
FROM `olist-pricing-analysis.olist.big_table`
UNION ALL
SELECT "Missing seller state", COUNTIF(seller_state IS NULL)
FROM `olist-pricing-analysis.olist.big_table`
UNION ALL
SELECT "Missing seller city", COUNTIF(seller_state IS NULL)
FROM `olist-pricing-analysis.olist.big_table`
UNION ALL
SELECT "Category = unknown", COUNTIF(category = 'unknown')
FROM `olist-pricing-analysis.olist.big_table`
UNION ALL
SELECT "Missing review score", COUNTIF(review_score IS NULL)
FROM `olist-pricing-analysis.olist.big_table`
UNION ALL
SELECT "Missing delivery days", COUNTIF(delivery_days IS NULL)
FROM `olist-pricing-analysis.olist.big_table`;

-- MISSING VALUES IN big_table (kept as NULL)
--   * 8 items without delivery_days: AVG and MEDIAN ignore NULL, so it's ok. Filling in 0 would artificially lower the average.
--   * 827 items without review_score: no review does not mean a score of 0 - we do not insert anything
--   * 1,537 items with category 'unknown' - we leave them as they are.
