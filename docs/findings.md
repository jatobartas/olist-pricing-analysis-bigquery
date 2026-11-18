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
