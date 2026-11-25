-- ===========================================================================================================================================
-- 04_price_position.sql
--   4.1 PRICES IN CATEGORIES (25TH, MEDIAN AND 75TH PERCENTILE)
--   4.2 PRICE DISPERSION WITHIN CATEGORIES (RATIO 75TH/25TH PERCENTILE - THE HIGHER RATIO THE WIDER RANGE OF PRICES - HIGHER DISPERSION)
--   4.3 TOP 20 ITEMS WITH THE HIGHEST PRICE TO MEDIAN INDEX (MEDIAN AS A MARKET LEVEL)

-- ==========================================================================================================================================
-- 4.1 PRICES IN CATEGORIES (25TH, MEDIAN AND 75TH PERCENTILE)

SELECT category,
       COUNT(*) AS items_sold,
       APPROX_QUANTILES(price, 100)[OFFSET(25)] AS price_p25,
       APPROX_QUANTILES(price, 100)[OFFSET(50)] AS median_price,
       APPROX_QUANTILES(price, 100)[OFFSET(75)] AS price_p75
FROM `olist-pricing-analysis.olist.big_table`
GROUP BY category
ORDER BY median_price DESC;

-- ==========================================================================================================================================
-- 4.2 PRICE DISPERSION WITHIN CATEGORIES (RATIO 75TH/25TH PERCENTILE - THE HIGHER RATIO THE WIDER RANGE OF PRICES - HIGHER DISPERSION)

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
-- 4.3 TOP 20 ITEMS WITH THE HIGHEST PRICE TO MEDIAN INDEX (MEDIAN AS A MARKET LEVEL)

SELECT *
FROM `olist-pricing-analysis.olist.big_table`;

SELECT seller_id, product_id, category, price,
ROUND(PERCENTILE_CONT(price, 0.5) OVER (PARTITION BY product_id), 2) AS median_product_price,
ROUND(price / PERCENTILE_CONT(price, 0.5) OVER (PARTITION BY product_id), 2) AS price_index
FROM `olist-pricing-analysis.olist.big_table`
ORDER BY price_index DESC
LIMIT 20;



