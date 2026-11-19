-- ===========================================================================================================================================
-- 04_price_position.sql
-- Project : Price Position and Market Analysis of an E-commerce Marketplace
-- Data    : Olist Brazilian E-Commerce dataset (Kaggle), loaded to BigQuery
--           as `olist-pricing-analysis.olist`
-- Purpose : Measure the price position of products and sellers against the market, using the base view big_table (delivered order items only). The market is defined as the median price in the same category and the median price of the same product across sellers (the data contains no competitor prices).
--
-- Contents
--   4.1 Category price levels
--   4.2 Seller price position (same product, different sellers)
--   4.3 Price position vs sales and customer satisfaction
-- =====================================================================

-- 4.1 Prices in categories
-- Typical price level per category: 25th percentile, median and 75th percentile of item price (the middle 50% of prices lies between the
-- 25th and 75th percentile).
-- Categories with fewer than 100 items are excluded from this ranking
-- because a ratio based on a few items is not reliable.

SELECT category,
       COUNT(*) AS items_sold,
       APPROX_QUANTILES(price, 100)[OFFSET(25)] AS price_p25,
       APPROX_QUANTILES(price, 100)[OFFSET(50)] AS median_price,
       APPROX_QUANTILES(price, 100)[OFFSET(75)] AS price_p75
FROM `olist-pricing-analysis.olist.big_table`
GROUP BY category
ORDER BY median_price DESC;

-- ==========================================================================================================================================
-- 4.2 PRICE DISPERSION WITHIN CATEGORIES
-- Ratio of the 75th to the 25th percentile of item price per category:
-- the higher the ratio, the wider the range of typical prices.
-- Categories with fewer than 100 items are excluded from this ranking
-- because a ratio based on a few items is not reliable.

WITH category_prices AS (
SELECT category,
       COUNT(*) AS items_sold,
       APPROX_QUANTILES(price, 100)[OFFSET(25)] AS price_p25,
       APPROX_QUANTILES(price, 100)[OFFSET(50)] AS median_price,
       APPROX_QUANTILES(price, 100)[OFFSET(75)] AS price_p75
FROM `olist-pricing-analysis.olist.big_table`
GROUP BY category
HAVING COUNT(*) >= 100
) SELECT category, items_sold, price_p25, median_price, price_p75, ROUND(SAFE_DIVIDE(price_p75, price_p25), 2) AS p75_p25_ratio
FROM category_prices
ORDER BY p75_p25_ratio DESC;

-- ==========================================================================================================================================
-- 4.3 SELLER PRICE POSITION
-- Price index = item price / median price of the same product (1.0 = market level).
-- All sellers and products are included.
-- Shows the 20 items with the highest price index.

SELECT *
FROM `olist-pricing-analysis.olist.big_table`;

SELECT seller_id, product_id, category, price,
ROUND(PERCENTILE_CONT(price, 0.5) OVER (PARTITION BY product_id), 2) AS median_product_price,
ROUND(price / PERCENTILE_CONT(price, 0.5) OVER (PARTITION BY product_id), 2) AS price_index
FROM `olist-pricing-analysis.olist.big_table`
ORDER BY price_index DESC
LIMIT 20;



