-- ===========================================================================================================================================
-- 01_data_check.sql
--   1.1 ROW COUNTS
--   1.2 TABLES PREVIEW
--   1.3 CHECK OF DISTINCT KEYS
--   1.4 MISSING DATA (IN THE MOST IMPORTANT COLUMNS)
--   1.5 CHECK OF ORDER STATUSES AND THEIR PART IN THE DATA + DATES RANGE (MAX/MIN)
--   1.6 PRICE AND FREIGHT CHECK (MAX/MIN, AVERAGE, MEDIAN, ZERO VALUES)
--   1.6 CHECK IF THE DATES ARE CONSISTENT AND IF THERE ARE ANY MISTAKES (ORDERS WITHOUT A DATE OR DELIVERED BEFORE THEY WERE PURCHASED)

-- ===========================================================================================================================================
--1.1 ROW COUNTS

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
--1.2 TABLES PREVIEW

SELECT * 
FROM `olist-pricing-analysis.olist.category_translation` 
LIMIT 10;

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
--1.3 CHECK OF DISTINCT KEYS

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
--1.4 MISSING DATA (IN THE MOST IMPORTANT COLUMNS)

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
--1.5 CHECK OF ORDER STATUSES AND THEIR PART IN THE DATA + DATES RANGE

SELECT * 
FROM `olist-pricing-analysis.olist.orders`
LIMIT 10;

SELECT order_status, COUNT(order_id) AS how_many_orders, ROUND(100*COUNT(*)/SUM(COUNT(*))OVER(), 2) AS percent
FROM `olist-pricing-analysis.olist.orders`
GROUP BY order_status
ORDER BY how_many_orders DESC;

SELECT MIN(order_purchase_timestamp) AS first_order, MAX(order_purchase_timestamp) AS last_order
FROM`olist-pricing-analysis.olist.orders`;

--==========================================================================================================================================
--1.4 PRICE AND FREIGHT CHECK (MAX/MIN, AVERAGE, MEDIAN, ZERO VALUES)

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
--1.6 CHECK IF THE DATES ARE CONSISTENT AND IF THERE ARE ANY MISTAKES (ORDERS WITHOUT A DATE OR DELIVERED BEFORE THEY WERE PURCHASED)

SELECT
  COUNTIF(order_status = 'delivered' AND order_delivered_customer_date IS NULL) AS delivered_without_date,
  COUNTIF(order_delivered_customer_date < order_purchase_timestamp) AS delivered_before_purchase
FROM `olist-pricing-analysis.olist.orders`;
