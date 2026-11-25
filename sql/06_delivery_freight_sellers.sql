-- ===========================================================================================================================================
-- 06_delivery_freight_sellers.sql
--   6.1 DELIVERY TIME AND REVIEW SCOREAND CORRELATION (ITEMS WITHOUT A DELIVERY DATE ARE EXCLUDED)
--   6.2 TOP 10 SELLERS BY REVENUE (AND THEIR AVARAGE REVIEW SCORE)
--   6.3 SAME STATE/CROSS STATE DIFFERENCES IN SHIPPING DELIVERY TIME AND FREIGHT COST

-- ==========================================================================================================================================
-- 6.1 DELIVERY TIME AND REVIEW SCOREAND CORRELATION (ITEMS WITHOUT A DELIVERY DATE ARE EXCLUDED)

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
-- 6.2 TOP 10 SELLERS BY REVENUE (AND THEIR AVERAGE REVIEW SCORE)

SELECT *
FROM `olist-pricing-analysis.olist.big_table`;

SELECT seller_id, ROUND(SUM(price), 2) AS revenue,ROUND(AVG(review_score), 2) AS avg_review_score
FROM `olist-pricing-analysis.olist.big_table`
GROUP BY seller_id
ORDER BY revenue DESC
LIMIT 10;

-- ==========================================================================================================================================
-- 6.3 SAME STATE/CROSS STATE DIFFERENCES IN SHIPPING DELIVERY TIME AND FREIGHT COST

SELECT
CASE WHEN seller_state = customer_state THEN 'same state'
ELSE 'different state'
END AS shipping_type,
ROUND(AVG(delivery_days), 2)AS avg_delivery_days,
ROUND(AVG(freight_value)) AS avg_freight_value
FROM `olist-pricing-analysis.olist.big_table`
GROUP BY shipping_type;
