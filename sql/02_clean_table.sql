-- ===========================================================================================================================================
-- 02_clean_table.sql
--   2.1 REVIEWS MADE TO BE ONE ROW PER ORDER
--   2.2 CREATION OF A ONE BIG TABLE CONTAINING EVERYTHING THAT IS NECESSARY FOR THE ANALYSIS (big_table)
--   2.3 VALIDATION (CHECK IF big_table WAS CREATED PROPERLY, IF ANY DATA WAS LOST AND NO ROWS ARE DUPLICATED)
--   2.4 SUMMARY (MISSING VALUES IN big_table)

----==========================================================================================================================================
-- 2.1 REVIEWS AGGREGATED TO ONE ROW PER ORDER

CREATE OR REPLACE VIEW `olist-pricing-analysis.olist.reviews_per_order` AS
SELECT order_id, ROUND(AVG(review_score), 2) AS review_score
FROM `olist-pricing-analysis.olist.order_reviews`
GROUP BY order_id;

-- ===========================================================================================================================================
-- 2.2 CREATION OF A ONE BIG TABLE CONTAINING EVERYTHING THAT IS NECESSERY FOR THE ANALYSIS (big_table)

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
-- 2.3 VALIDATION (CHECK IF BIG TABLE WAS CREATED PROPERLY, IF ANY DATA WAS LOST AND NO ROWS ARE DUPLICATED)

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

--============================================================================================================================================
-- 2.4 SUMMARY (MISSING VALUES IN big_table)

-- 8 items without delivery_days: AVG and MEDIAN ignore NULL, so it's ok. 
-- Filling in 0 would lower the average.
-- 827 items without review_score: no review =/= score of 0. We do not insert anything.
-- 1,537 items with category 'unknown' - we leave them as they are.
