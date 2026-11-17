-- ===========================================================================================================================================
-- 01_data_check.sql
-- Project : Price Position and Market Analysis of an E-commerce Marketplace
-- Data    : Olist Brazilian E-Commerce dataset (Kaggle), loaded to BigQuery
--           as `olist-pricing-analysis.olist`
-- Purpose : Check the quality of the raw tables before building the analysis.
--
-- Structure
--   0.1 Row counts
--   0.2 One-time fix: category_translation header row (do not run again)
--   0.3 Tables preview
--   1.1 Distinct keys
--   1.2 Missing data in key columns
--   1.3 Order statuses and date range
--   1.4 Price and freight check
--   1.5 Delivery date consistency

-- ===========================================================================================================================================
--0.1 ROW COUNTS
SELECT 'orders' AS table_name, COUNT(*) AS row_count
FROM `olist-pricing-analysis.olist.orders`
UNION ALL
SELECT 'order items', COUNT(*)
FROM `olist-pricing-analysis.olist.order_items`
UNION ALL
SELECT 'products', COUNT(*)
FROM `olist-pricing-analysis.olist.products`
UNION ALL
SELECT 'customers', COUNT(*)
FROM `olist-pricing-analysis.olist.customers`
UNION ALL
SELECT 'sellers', COUNT(*)
FROM `olist-pricing-analysis.olist.sellers`
UNION ALL
SELECT 'order_payments', COUNT(*)
FROM `olist-pricing-analysis.olist.order_payments`
UNION ALL
SELECT 'order_reviews', COUNT(*)
FROM `olist-pricing-analysis.olist.order_reviews`
UNION ALL
SELECT 'category_translation', COUNT(*)
FROM `olist-pricing-analysis.olist.category_translation`
UNION ALL
SELECT 'geolocation', COUNT(*)
FROM `olist-pricing-analysis.olist.geolocation`;

-- ===========================================================================================================================================
-- 0.2 ONE-TIME FIX (already applied, do not run again)
-- The header row of category_translation was loaded as data and the columns were named string_field_0 / string_field_1. 
-- This statement renamed the columns and removed the header row (72 -> 71 rows).

-- CREATE OR REPLACE TABLE `olist-pricing-analysis.olist.category_translation` AS
-- SELECT
--   string_field_0 AS product_category_name,
--   string_field_1 AS product_category_name_english
-- FROM `olist-pricing-analysis.olist.category_translation`
-- WHERE string_field_0 != 'product_category_name';

-- ===========================================================================================================================================
--0.3 TABLES PREVIEW
SELECT * 
FROM `olist-pricing-analysis.olist.category_translation` 
LIMIT 5;

SELECT COUNT(*) AS total_rows 
FROM `olist-pricing-analysis.olist.category_translation`;

SELECT *
FROM `olist-pricing-analysis.olist.orders`
LIMIT 10;

SELECT *
FROM `olist-pricing-analysis.olist.order_items`
LIMIT 10;

SELECT *
FROM `olist-pricing-analysis.olist.products`
LIMIT 10;

SELECT *
FROM `olist-pricing-analysis.olist.category_translation`
LIMIT 10;

-- ===========================================================================================================================================
--1.1 CHECK OF DISTINCT KEYS
-- If total_rows = distinct_keys, the key is unique and safe to join on.
-- If distinct_keys is smaller, the key repeats and the table must be
-- aggregated before joining, otherwise rows (and prices) get duplicated.
--   * customers: customer_id is assigned per order; customer_unique_id
--     identifies the real customer (repeat buyers make it smaller).
--   * order_payments: one order can have several payments (installments,
--     several payment methods), so order_id alone is not unique.
--     (order_id, payment_sequential) is built with CONCAT; CAST turns
--     the number into text. Aggregate payments per order before joining
--     to order_items, otherwise item prices get duplicated.
--   * order_reviews: an order can have more than one review.
--   * geolocation: many rows per zip code prefix.

SELECT 'orders' AS table_name, COUNT(*) AS row_count, COUNT(DISTINCT(order_id)) AS distinct_rows_count
FROM `olist-pricing-analysis.olist.orders`
UNION ALL
SELECT 'order_items (order_id + order_item_id)', COUNT(*),COUNT(DISTINCT CONCAT(order_id, '-', CAST(order_item_id AS STRING)))
FROM `olist-pricing-analysis.olist.order_items`
UNION ALL
SELECT 'products', COUNT(*), COUNT(DISTINCT(product_id))
FROM `olist-pricing-analysis.olist.products`
UNION ALL
SELECT 'customers', COUNT(*), COUNT(DISTINCT customer_unique_id)
FROM `olist-pricing-analysis.olist.customers`
UNION ALL
SELECT 'sellers', COUNT(*), COUNT(DISTINCT seller_id)
FROM `olist-pricing-analysis.olist.sellers`
UNION ALL
SELECT 'order_payments', COUNT(*),  COUNT(DISTINCT CONCAT(order_id, '-', CAST(payment_sequential AS STRING))) AS distinct_keys 
FROM `olist-pricing-analysis.olist.order_payments`
UNION ALL
SELECT 'order_reviews', COUNT(*), COUNT(DISTINCT order_id)
FROM `olist-pricing-analysis.olist.order_reviews`
UNION ALL
SELECT 'category_translation (product_category_name)',COUNT(*),COUNT(DISTINCT product_category_name)
FROM `olist-pricing-analysis.olist.category_translation`
UNION ALL
SELECT 'geolocation (zip code prefix)', COUNT(*),COUNT(DISTINCT geolocation_zip_code_prefix)
FROM `olist-pricing-analysis.olist.geolocation`;

--===========================================================================================================================================
--1.2 MISSING DATA IN KEY COLUMNS
-- Finding: 160 orders without approval date, 2,965 without delivery date (not delivered), 610 products without category, 2 without weight.
-- Price, freight, seller, states, payment value and review score are complete.

SELECT 'orders' AS table_name, 'order_approved_at' AS column_name,COUNTIF(order_approved_at IS NULL) AS null_rows, COUNT(*) AS total_rows
FROM `olist-pricing-analysis.olist.orders`
UNION ALL
SELECT 'orders', 'order_delivered_customer_date',COUNTIF(order_delivered_customer_date IS NULL), COUNT(*)
FROM `olist-pricing-analysis.olist.orders`
UNION ALL
SELECT 'order_items', 'price', COUNTIF(price IS NULL), COUNT(*)
FROM `olist-pricing-analysis.olist.order_items`
UNION ALL
SELECT 'order_items', 'freight_value', COUNTIF(freight_value IS NULL), COUNT(*)
FROM `olist-pricing-analysis.olist.order_items`
UNION ALL
SELECT 'order_items', 'seller_id', COUNTIF(seller_id IS NULL), COUNT(*)
FROM `olist-pricing-analysis.olist.order_items`
UNION ALL
SELECT 'products', 'product_category_name',COUNTIF(product_category_name IS NULL OR product_category_name = ''), COUNT(*)
FROM `olist-pricing-analysis.olist.products`
UNION ALL
SELECT 'products', 'product_weight_g', COUNTIF(product_weight_g IS NULL), COUNT(*)
FROM `olist-pricing-analysis.olist.products`
UNION ALL
SELECT 'customers', 'customer_state', COUNTIF(customer_state IS NULL), COUNT(*)
FROM `olist-pricing-analysis.olist.customers`
UNION ALL
SELECT 'sellers', 'seller_state', COUNTIF(seller_state IS NULL), COUNT(*)
FROM `olist-pricing-analysis.olist.sellers`
UNION ALL
SELECT 'order_payments', 'payment_value', COUNTIF(payment_value IS NULL), COUNT(*)
FROM `olist-pricing-analysis.olist.order_payments`
UNION ALL
SELECT 'order_reviews', 'review_score', COUNTIF(review_score IS NULL), COUNT(*)
FROM `olist-pricing-analysis.olist.order_reviews`;

--===========================================================================================================================================
--1.3 Order statuses and date range
-- A) Distribution of order statuses: how many orders per status.
--    Used to decide which orders to include in the analysis.
--    Finding: 97.02% of orders are "delivered".
SELECT * 
FROM `olist-pricing-analysis.olist.orders`
LIMIT 10;

SELECT order_status, COUNT(order_id) AS how_many_orders, ROUND(100*COUNT(*)/SUM(COUNT(*))OVER(), 2) AS percent
FROM `olist-pricing-analysis.olist.orders`
GROUP BY order_status
ORDER BY how_many_orders DESC;
--===========================================================================================================================================
---- B) Date range of purchases: first and last order date.
--    Defines the period covered by the data and the validity of monthly trends.
--    Finding: 2016-09-04 to 2018-10-17.
SELECT MIN(order_purchase_timestamp) AS first_order, MAX(order_purchase_timestamp) AS last_order
FROM`olist-pricing-analysis.olist.orders`;

--==========================================================================================================================================
--1.4 Price and freight check: range, average, median, zero values.
-- Range, average, median (50th percentile) and 99th percentile of price, and range, average and number of zero values for freight.
-- APPROX_QUANTILES(x, 100) returns percentiles 0-100 as a list;
-- OFFSET(50) is the median.
-- Finding: price 0.85-6,735 (mean 120.65), freight 0-409.68
-- (mean 19.99), 383 items with free shipping.

SELECT COUNT(*) AS ITEMS,
MIN(price) AS min_price,
MAX(price) AS max_price,
ROUND(AVG(PRICE), 2) AS avg_price,
APPROX_QUANTILES(price, 100)[OFFSET(50)] AS median_price,
APPROX_QUANTILES(price, 100)[OFFSET(99)] AS p99_price,
MIN(freight_value) AS min_freight,
MAX(freight_value) AS max_freight,
ROUND(AVG(freight_value), 2) AS avg_freight,
COUNTIF(freight_value = 0) AS zero_freight
FROM `olist-pricing-analysis.olist.order_items`;

--==========================================================================================================================================
--1.5 Check if the dates are consistent and check of the deliveries with mistakes
-- Delivered orders without a delivery date, and orders delivered before they were purchased.
-- Finding: 8 delivered orders without a delivery date, 0 delivered before purchase.
SELECT
  COUNTIF(order_status = 'delivered' AND order_delivered_customer_date IS NULL) AS delivered_without_date,
  COUNTIF(order_delivered_customer_date < order_purchase_timestamp) AS delivered_before_purchase
FROM `olist-pricing-analysis.olist.orders`;
