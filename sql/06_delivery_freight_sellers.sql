-- ===========================================================================================================================================
-- Project:  Price Position and Market Analysis of an E-commerce Marketplace
-- File:     06_delivery_freight_sellers.sql
-- Purpose:  Explore delivery time, freight cost and seller performance.
--
-- Contents:
--   6.1 Delivery time and review score
--   6.2 Top 10 sellers by revenue
--   6.3 Same-state vs cross-state shipping
-- ==========================================================================================================================================
-- 6.1 DELIVERY TIME AND REVIEW SCORE
-- Items are grouped by delivery time; we compare the average review score.
-- Items without a delivery date are excluded.

SELECT *
FROM `olist-pricing-analysis.olist.big_table`;

SELECT 
CASE 
WHEN delivery_days <= 7 THEN '1) Up to 7 days'
WHEN delivery_days <= 14 THEN '2) 8 to 14 days'
WHEN delivery_days <= 21 THEN '3) 15 to 21 days'
ELSE 'Over 21 days' 
END AS delivery_days_group,
COUNT(*) AS items_sold,
ROUND(AVG(review_score), 2) AS avarage_review_score
FROM `olist-pricing-analysis.olist.big_table`
WHERE delivery_days IS NOT NULL
GROUP BY delivery_days_group
ORDER BY delivery_days_group;
--==========================================================================================================================================
-- 6.2 TOP 10 SELLERS BY REVENUE
-- Shows revenue and average review score of the ten biggest sellers.

SELECT *
FROM `olist-pricing-analysis.olist.big_table`;

SELECT seller_id, ROUND(SUM(price), 2) AS revenue,ROUND(AVG(review_score), 2) AS avg_review_score
FROM `olist-pricing-analysis.olist.big_table`
GROUP BY seller_id
ORDER BY revenue DESC
LIMIT 10;

-- ==========================================================================================================================================
-- 6.3 SAME-STATE VS CROSS-STATE SHIPPING
-- Compares delivery time and freight when seller and customer share a state.

SELECT
CASE WHEN seller_state = customer_state THEN 'same state'
ELSE 'different state'
END AS shipping_type,
ROUND(AVG(delivery_days), 2)AS avg_delivery_days,
ROUND(AVG(freight_value)) AS avg_freight_value
FROM `olist-pricing-analysis.olist.big_table`
GROUP BY shipping_type;







