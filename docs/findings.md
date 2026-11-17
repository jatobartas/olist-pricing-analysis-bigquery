## Data check: missing values
- table orders, column - order_approved_at: 160 missing values (probably anulled or not accepted)
- table orders, column - order_delivered_customer_date: 2965 missing values (not delivered or anulled during the delivery)
- table products, column - product_category_name: 610 missing values (products without category, unknown)

## Data check: order statuses and date range
- 97.02% of orders (96,478 of 99,441) have the status "delivered". The remaining statuses are shipped (1.11%), canceled (0.63%), unavailable (0.61%), invoiced (0.32%), processing (0.30%), created (0.01%) and approved (<0.01%).
- The analysis uses delivered orders only, because they represent completed sales with final prices, freight costs and review scores; the excluded 3% would add incomplete or cancelled transactions.
- The data covers purchases from 2016-09-04 to 2018-10-17. The edges of this period may be incomplete; monthly trends should be checked for sparse months before drawing conclusions.
## Data check: prices, freight and delivery dates
- The 112,650 order items have prices between 0.85 and 6,735 BRL (mean 120.65); there are no zero or negative prices.
- Freight values range from 0 to 409.68 (mean 19.99); 383 items (0.34%) have free shipping.
- The large gap between maximum and mean price suggests a right-skewed price distribution, so medians are used instead of means for price comparisons. Median price: 74.99 so 50% of the prices are under 74.99 and 50% are over. The value for the 99. percentil is 890.0, so 99% of the prices are below that value.
- 8 orders with status "delivered" have no delivery date; they are excluded from delivery-time metrics only. No order was delivered before it was purchased.
