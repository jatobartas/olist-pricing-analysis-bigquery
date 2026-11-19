## Data check: distinct keys
- Primary keys are unique in orders (99,441), order_items (112,650; key: order_id + order_item_id), products (32,951), sellers (3,095), order_payments (103,886; key: order_id + payment_sequential) and category_translation (71), so these tables can be joined safely.
- customers has 99,441 rows but only 96,096 distinct customer_unique_id values: customer_id is assigned per order, so 3,345 rows come from repeat buyers.
- order_reviews has 99,224 rows but only 98,673 distinct orders (551 more rows than orders): some orders have more than one review, so reviews are aggregated to one row per order before joining.
- geolocation has 1,000,163 rows for 19,015 zip code prefixes, so it is not joined directly to other tables.
## Data check: missing values
- table orders, column - order_approved_at: 160 missing values (probably canceled or not accepted)
- table orders, column - order_delivered_customer_date: 2965 missing values (not delivered or canceled during the delivery)
- table products, column - product_category_name: 610 missing values (products without category, unknown)
## Data check: order statuses and date range
- 97.02% of orders (96,478 of 99,441) have the status "delivered". The remaining statuses are shipped (1.11%), canceled (0.63%), unavailable (0.61%), invoiced (0.32%), processing (0.30%), created (0.01%) and approved (<0.01%).
- The analysis uses delivered orders only, because they represent completed sales with final prices, freight costs and review scores; the excluded 3% would add incomplete or cancelled transactions.
- The data covers purchases from 2016-09-04 to 2018-10-17. The edges of this period may be incomplete; monthly trends should be checked for sparse months before drawing conclusions.
## Data check: prices, freight and delivery dates
- The 112,650 order items have prices between 0.85 and 6,735 BRL (mean 120.65); there are no zero or negative prices.
- Freight values range from 0 to 409.68 (mean 19.99); 383 items (0.34%) have free shipping.
- The large gap between maximum and mean price suggests a right-skewed price distribution, so medians are used instead of means for price comparisons. Median price: 74.99 so 50% of the prices are under 74.99 and 50% are over. The value for the 99th percentil is 890.0, so 99% of the prices are below that value.
- 8 orders with status "delivered" have no delivery date; they are excluded from delivery-time metrics only. No order was delivered before it was purchased.
## Base view: big_table
- big_table has one row per delivered order item (110,197 rows). The row count matches the delivered order items in the source tables and every item key (order_id + order_item_id) is unique, so no join duplicated or lost rows.
- Customer and seller states and cities have no missing values. 8 items have no delivery_days (delivered orders without a delivery date), 827 have no review score (orders without reviews) and 1,537 have the category "unknown" (products without category).
- Reviews are averaged per order before joining and payments are not joined, because both can have several rows per order and would duplicate item values.
- Missing values are kept as NULL and are not imputed. Averages ignore them: delivery time uses items with a delivery date (99.993% of items), review scores use rated items only (99.25%). Items with category "unknown" (1.39%) stay in totals and are reported separately in category breakdowns.
## KPIs: overall
- Delivered orders: 110,197 items in 96,478 orders, from 93,358 unique customers, 2,970 sellers and 32,216 products.
- Revenue (item prices, excluding freight) is 13,221,498.11 BRL; total freight is 2,198,275.64 BRL.
- The average order value is 137.04 BRL, the average item price is 119.98 BRL and the median item price is 74.90 BRL. The 99th percentile of the item price is 888.90 BRL.
- The average delivery time is 12.0 days and the average review score is 4.08.
## KPIs: monthly trend
- The first months of the data are too sparse for trend analysis: 3 items in Sep 2016, 313 in Oct 2016, no sales in Nov 2016 and 1 item in Dec 2016. Trends will be therefore shown from Jan 2017.
- Excluding the first 3 months the lowest value of items sold was in Jan 2017 which was equal to 913. The peak was in Nov 2017 which could be driven by Black Friday.
- The highest revenue also occurred in Nov 2017 (987765.37 BRL)
- The average order value stayed between 124 and 149 BRL without a clear trend, so growth came from the number of orders rather than larger baskets.
## KPIs: top 10 categories by revenue
- The highest selling categories are 1. health_beauty (1233131.72 BRL), 2. watches_gifts (1166176.98 BRL), 3. bed_bath_table (1023434.76 BRL)
- Bed_bath_table sold the most items (10,953). Watches are second in revenue with only 5859 items sold.
- From the top 10 category in revenue, the furniture_decor has the lowest average prices (87.25 BRL) and housewares (90.60 BRL)
- In every top 10 category the average price is higher than the median price (e.g. health_beauty: 130.28 vs 79.90 BRL; watches_gifts: 199.04 vs 128.90 BRL). This means that the distribution is right-skewed and a smaller number of expensive items pulls the average up, so the median is gonna describe a typical price better.
## Price position: price dispersion within categories
- Among categories with at least 100 items, the widest price dispersion (ratio of the 75th to the 25th price percentile) is in agro_industry_and_commerce (12.0; 35.0 BRL vs 420.0 BRL), followed by audio (8.79), costruction_tools_tools (6.35), small_appliances (6.09), christmas_supplies (5.80), musical_instruments (5.45) and consoles_games (5.27). The name costruction_tools_tools is spelled this way in the source data.
- The narrowest dispersion is in industry_commerce_and_business (1.51), fashion_underwear_beach (1.60) and office_furniture (1.63).
- A wide ratio can also mean that a category contains different types of products, so it does not by itself prove inconsistent pricing; this is checked at product level in the next step.
## Price position: offers vs the market price of the same product
- The offer furthest above the median price of the same product is a perfumery item sold for 99.00 BRL against a median of 23.90 BRL (price index 4.14), followed by a consoles_games item at 159.99 BRL against 49.99 BRL (3.20).
- The other top rows shown have price indices between 2.50 and 2.73, e.g. agro_industry_and_commerce (59.99 vs 21.99 BRL) and health_beauty (95.00 vs 35.00 BRL).
- The same offer can appear several times because each row is one sold item; one seller appears twice among the top rows shown (agro_industry_and_commerce and telephony).
## Regional markets: metrics by customer state
- SP has by far the highest revenue (5,067,633.16 BRL), followed by RJ (1,759,651.13 BRL) and MG (1,552,481.83 BRL); the lowest revenue among the 27 states is in RR (7,057.47 BRL).
- SP also has the shortest average delivery time (8.26 days) and the lowest average freight (15.12 BRL), and the lowest average item price (109.10 BRL) among the states shown.
- The longest average delivery times are in RR (27.83 days), AP (27.75 days) and AM (25.96 days). RR and PB have the highest average freight (43.09 BRL).
- The lowest average review scores are in MA (3.76), PA (3.84), BA (3.86), RJ (3.87) and CE (3.87); the highest is in AP (4.26), followed by SP (4.18).
- The highest average item prices are in PB (about 192 BRL), AL (184.67 BRL) and AC (175.07 BRL).
- ## Regional markets: top cities by revenue
- The city with the highest revenue is sao paulo (SP) with 1,859,556.83 BRL, followed by rio de janeiro (RJ) with 955,573.97 BRL and belo horizonte (MG) with 346,039.04 BRL.
- The three cities from SP among the top 10 (sao paulo, campinas, guarulhos) have the shortest delivery times (7.56, 9.23 and 7.60 days) and the lowest average freight (14.28, 14.97 and 14.47 BRL).
- salvador (BA) has the highest average freight (25.36 BRL), the longest average delivery time (18.68 days) and the lowest average review score (3.74) among the 10 cities shown.
- Both RJ cities in the top 10 (rio de janeiro and niteroi) have average review scores below 4.0 (3.91 and 3.92).
