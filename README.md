# Analysis of an E-commerce Marketplace Olist with BigQuery & Looker Studio

## Introduction
This project analyses data of Brazilian E-Commerce website Olist using BigQuery and Looker Studio. The main goal of the analysis is to draw some insights from the Data and to create specific business recomendations depending on the outcome. The focus is put on understanding the market sells, prices (across categories), sales (across regions), delivery time, freight cost and customer satisfaction.

## Analysis (BigQuery & Looker Studio)

### 1. Data Check

This part of project is dedicated for the check of the quality of 9 tables that are included in the Dataset (from Kaggle). The process is conducted in BigQuery and is carried out to ensure the quality of the analysis. The full code is available in [`sql/01_data_check.sql`](sql/01_data_check.sql).

#### 1. Row counts - to get to know the data and see with how big dataset will I be working with. All CSV tables were loaded correctly. 

<div align="center">
  
| table_name           | row_count |
|----------------------|----------:|
| orders               |    99,441 |
| order_items          |   112,650 |
| products             |    32,951 |
| customers            |    99,441 |
| sellers              |     3,095 |
| order_payments       |   103,886 |
| order_reviews        |    99,224 |
| category_translation |        71 |
| geolocation          | 1,000,163 |

</div>

Order_items may have a bit more rows than order_items - it may be because one order may contain multiple items. 
We are starting with almost a 100k orders, 33k products, over 3k sellers. The thing that may gather attention is that orders and customers are the same number. It will have to be checked later.

#### 2. Tables preview - to see the column names and example data across different tables. The example query outcome is showed below.

<div align="center">

| product_category_name | product_category_name_english |
|:---|:---|
| alimentos_bebidas | food_drink |
| malas_acessorios | luggage_accessories |
| beleza_saude | health_beauty |
| fashion_bolsas_e_acessorios | fashion_bags_accessories |
| alimentos | food |
| fashion_underwear_e_moda_praia | fashion_underwear_beach |
| audio | audio |
| portateis_casa_forno_e_cafe | small_appliances_home_oven_and_coffee |
| construcao_ferramentas_seguranca | construction_tools_safety |
| eletrodomesticos | home_appliances |

</div>

#### 3. Check of distinct keys - to see if the keys are unique so joining the tables would be safe and not duplicate the rows.

<div align="center">

| table_name | row_count | distinct_rows_count |
|:---|---:|---:|
| orders | 99441 | 99441 |
| order_items (order_id + order_item_id) | 112650 | 112650 |
| products | 32951 | 32951 |
| customers | 99441 | 96096 |
| sellers | 3095 | 3095 |
| order_payments | 103886 | 103886 |
| order_reviews | 99224 | 98673 |
| category_translation (product_category_name) | 71 | 71 |
| geolocation (zip code prefix) | 1000163 | 19015 |

</div>

Key are unique in: orders, products, sellers, category_translation. For order_items and order_payments it was needed to create a distinct key with forcing together order_id + order_item_id for order_items and order_id + payment_sequential for order_payments. Thanks to that - they can be joined safely. Customers has 99441 rows but only 96096 distinct customer_unique_id values (customer_id may be assigned per order). Customers will be counted with customer_unique_id. Order_reviews will be changed later to create a possibility of joining them with the rest of the data. Geolocation will not be joined to the other tables. 

#### 4. Missing data in the most important columns - missing values decide which rows can be used - we can't calculate the average delivery date for rows without delivery time.

<div align="center">

| table_name | column_name | null_rows | total_rows |
|:---|:---|---:|---:|
| orders | order_approved_at | 160 | 99441 |
| orders | order_delivered_customer_date | 2965 | 99441 |
| order_items | price | 0 | 112650 |
| order_items | freight_value | 0 | 112650 |
| order_items | seller_id | 0 | 112650 |
| products | product_category_name | 610 | 32951 |
| products | product_weight_g | 2 | 32951 |
| customers | customer_state | 0 | 99441 |
| sellers | seller_state | 0 | 3095 |
| order_payments | payment_value | 0 | 103886 |
| order_reviews | review_score | 0 | 99224 |

</div>

Columns containing NULLs - order_approved_at (orders), order_delivered_customer_date (orders), product_category_name (products), product_weight_g (products).
The column with time of approval won't be used. For the calculation of metrics with delivery date, metrics will use only the delivered ones, 610 products have no category so they will be marked as "uknown" so we don't loose the data. 2 products have no weight but it won't be needed for the analysis.

#### 5. Check of order statuses and their share in the data + date range - to check how many orders we're delivered (and their other statuses). Also to check what is the timestamp.
   
<div align="center">

| order_status | how_many_orders | percent |
|:---|---:|---:|
| delivered | 96478 | 97.02 |
| shipped | 1107 | 1.11 |
| canceled | 625 | 0.63 |
| unavailable | 609 | 0.61 |
| invoiced | 314 | 0.32 |
| processing | 301 | 0.3 |
| created | 5 | 0.01 |
| approved | 2 | 0.0 |

</div>

Delivered orders have 97% of the whole deliveries, shipped have 1% (they were probably canceled during the shipping) and canceled have only 0,63% of the orders.

<div align="center">

| first_order | last_order |
|:---:|:---:|
| 2016-09-04 21:15:19 UTC | 2018-10-17 17:30:18 UTC |

</div>

The first order was issued on 4th of September 2016, and the last one on 17th of October 2018. The timestamp is more than 2 years.

#### 6. Price and freight check (min/max, average, median, zero values) - to see the range of prices and freight costs and to spot extreme or zero values before calculating averages and medians.

<div align="center">

| items | min_price | max_price | avg_price | median_price | p99_price | min_freight | max_freight | avg_freight | zero_freight |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 112650 | 0.85 | 6735.0 | 120.65 | 74.99 | 890.0 | 0.0 | 409.68 | 19.99 | 383 |

</div>

Item prices vary from 0.85 BRL to 6735 BRL. Average price is 120.65, median is 74.99 (Median is smaller than the average so it implies right-skeweness of the distribution - most of the products have smaller prices but some of them have much higher and that's why mean chases the tail and ends up higher than the median). The freight varies from 0 to 409.68 BRL and it's average is 20 BRL. Amount of orders with zero freight - 383.

#### 7. Check if the dates are consistent and if there are any errors (orders without a date or delivered before they were purchased)

<div align="center">

| delivered_without_date | delivered_before_purchase |
|:---:|:---:|
| 8 | 0 |

</div>

Eight of the orders were delivered without a delivery date and 0 were delivered before purchase - everything works.

### 2. Cleaning

The raw data is spread across 9 tables. To avoid repeating the same joins in every query, one base view called big_table was created. It contains everything needed for the analysis, with one row per delivered order item.

#### 1. Reviews made to be one row per order** - The data check in 1.3 showed that some of the orders have more than one review. Joining reviews directly to order items would duplicate those items and inflate revenue and item counts. A view reviews_per_order was created with the average score per order. After this every order has at maximum one review - it can be joined safely now.
#### 2. Creation of one big table containing everything necessary for the analysis (big_table)** - a single table will be used for all the analysis queries. It was built step by step by joining: order_items + orders (purchase dates and delivery dates) + customers (customer_unique_id, customer state and city) + sellers (seller state and city) + reviews_per_order + products + category_translation (review score and product category). For the first join (items and orders) INNER JOIN was used to get only these rows that occur in both of the tables. For the rest (after having items and their orders) we join the rest with LEFT JOIN, so that we have everything that is in the base table and only those rows that are shared in this and the other tables.
<div align="center">
   <img width="640" height="360" alt="image" src="https://github.com/user-attachments/assets/9e76caf7-5a96-4ab5-8c59-8d3ab92c3322" />
</div>

<div align="center">

| order_id | order_item_id | product_id | seller_id | price | freight_value | customer_id | purchase_date | purchase_month | delivery_days | freight_share_of_price | customer_unique_id | customer_state | customer_city | seller_state | seller_city | review_score | portuguese_category | category |
|:---|---:|:---|:---|---:|---:|:---|:---|:---|---:|---:|:---|:---|:---|:---|:---|---:|:---|:---|
| 3ee6513ae7ea23bdfab5b9ab60bffcb5 | 1 | 8a3254bee785a526d548a81a9bc3c9be | 96804ea39d96eb908e7c3afdb671bb9e | 0.85 | 18.23 | 161b6d415e8b3413c6609c70cf405b5a | 2018-04-24 | 2018-04-01 | 13 | 21.447 | d80730c15c647bc8f2ad77c908ba5ca9 | SP | hortolandia | MG | ibia | 4.0 | construcao_ferramentas_construcao | construction_tools_construction |
| 6e864b3f0ec71031117ad4cf46b7f2a1 | 1 | 8a3254bee785a526d548a81a9bc3c9be | 96804ea39d96eb908e7c3afdb671bb9e | 0.85 | 18.23 | 9f9d249355f63c5c1216a82b802452c1 | 2018-04-24 | 2018-04-01 | 9 | 21.447 | b38211bd797f4fdd81a98b9d1754b606 | RJ | duque de caxias | MG | ibia | 5.0 | construcao_ferramentas_construcao | construction_tools_construction |
| c5bdd8ef3c0ec420232e668302179113 | 2 | 8a3254bee785a526d548a81a9bc3c9be | 96804ea39d96eb908e7c3afdb671bb9e | 0.85 | 22.3 | 5af78bf1a82a2660d1e3fd78c645f58f | 2018-04-27 | 2018-04-01 | 8 | 26.235 | f006d7920bd71c252f61ec355eb50dcb | SP | cotia | MG | ibia | 1.0 | construcao_ferramentas_construcao | construction_tools_construction |

</div>

And the big_table is created.

#### 3. Validation (check if big_table was created properly, if any data was lost and no rows are duplicated)
<div align="center">

| check_name | value |
|:---|---:|
| Missing customer city | 0 |
| Distinct keys in the big table (order_id + order_item_id) | 110197 |
| Missing delivery days | 8 |
| Missing review score | 827 |
| Category = unknown | 1537 |
| Missing seller city | 0 |
| Missing seller state | 0 |
| Expected rows (delivered) | 110197 |
| Missing customer state | 0 |
| How many rows | 110197 |

</div>

Table big_table has 110197 rows like it supposed to and every item key (order_id + order_item_id) is unique. 

#### 4. Summary (missing values in big_table)

Eight items have no delivery_days. The average and median ignore NULL so we leave them as they are. Filling in 0 would artificially lower the average delivery days. 827 items have no review score - no review doesn't mean a score of 0 so nothing is filled in. 1537 items are with a category 'unknown'. They are left here so the total analysis stays complete.

### 3. Overview

This stage describes the scale of the marketplace and sets reference values for all later analyses. All KPIs are calculated from big_table, so they cover delivered order items only.

#### 1. Overall KPIs - to find out basic business numbers as items sold, revenue, orders, sellers, customers, freight etc.

Revenue is caluclated as sum of price, average order value is revenue divided by the number of distinct orders (one order can have multiple items so it has to be the amount of orders), customers are counted with customer_unique_id, median and 99th percentile are added because some of the items may pull the mean up. 

<div align="center">

| items_sold | orders | products | sellers | customers | revenue | mln_revenue | total_freight | average_order_value | avg_price | median_item_price | ninetynine_percentil_price | average_delivery_days | average_review_score |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 110197 | 96478 | 32216 | 2970 | 93358 | 13221498.11 | 13.221 | 2198275.64 | 137.04 | 119.98 | 74.9 | 888.9 | 12.0 | 4.08 |

</div>

The delivered orders contain 110197 items delivered in 96478 orders, sold by 2970 sellers across 32216 products - sold to 93358 customers. Revenue is 13.22 milion BRL and the freight is 2.19 mln BRL. The average order value is 137.04 BRL, an average order price is 119.98. Orders are delivered on average in 12 days and the average review score is 4.08/5.

#### 2. Monthly trend - to see how sales changed over time, find peak and lowest months, and check whether the peaks were caused by bigger sales or bigger basket (more items).

The first 3 months are to sparse for analysis so they won't be taken into account.

<div align="center">

| purchase_month | items_sold | revenue | average_order_value |
|:---|---:|---:|---:|
| 2016-09-01 | 3 | 134.97 | 134.97 |
| 2016-10-01 | 313 | 40325.11 | 152.17 |
| 2016-12-01 | 1 | 10.9 | 10.9 |
| 2017-01-01 | 913 | 111798.36 | 149.06 |
| 2017-02-01 | 1858 | 234223.4 | 141.7 |
| 2017-03-01 | 2897 | 359198.85 | 141.08 |
| 2017-04-01 | 2569 | 340669.68 | 147.92 |
| 2017-05-01 | 4004 | 489338.25 | 138.0 |
| 2017-06-01 | 3489 | 421923.37 | 134.58 |
| 2017-07-01 | 4416 | 481604.52 | 124.38 |
| 2017-08-01 | 4797 | 554699.7 | 132.29 |
| 2017-09-01 | 4737 | 607399.67 | 146.36 |
| 2017-10-01 | 5214 | 648247.65 | 144.76 |
| 2017-11-01 | 8475 | 987765.37 | 135.51 |
| 2017-12-01 | 6187 | 726033.19 | 131.69 |
| 2018-01-01 | 8037 | 924645.0 | 130.8 |
| 2018-02-01 | 7518 | 826437.13 | 126.08 |
| 2018-03-01 | 8017 | 953356.25 | 136.14 |
| 2018-04-01 | 7827 | 973534.09 | 143.21 |
| 2018-05-01 | 7810 | 977544.69 | 144.84 |
| 2018-06-01 | 7010 | 856077.86 | 140.36 |
| 2018-07-01 | 6963 | 867953.46 | 140.92 |
| 2018-08-01 | 7142 | 838576.64 | 132.04 |

</div>

Sales grew from 913 items (40325.11 BRL revenue) in January 2017 to it's peak of 8475 (987765.37 BRL revenue) in November 2017. The average order value was oscillating around the mean (137,04 BRL) and the revenue grew bigger. This means that sales grew because customers placed more orders, not because their baskets were more expensive.

#### 3. Top 10 categories - to find which product categories bring the most revenue, how many items they sold, their average price and median.

<div align="center">

| category | revenue | items_sold | average_price | median_price |
|:---|---:|---:|---:|---:|
| health_beauty | 1233131.72 | 9465 | 130.28 | 79.9 |
| watches_gifts | 1166176.98 | 5859 | 199.04 | 128.9 |
| bed_bath_table | 1023434.76 | 10953 | 93.44 | 79.57 |
| sports_leisure | 954852.55 | 8431 | 113.25 | 76.9 |
| computers_accessories | 888724.61 | 7644 | 116.26 | 81.99 |
| furniture_decor | 711927.69 | 8160 | 87.25 | 65.49 |
| housewares | 615628.69 | 6795 | 90.6 | 59.7 |
| cool_stuff | 610204.1 | 3718 | 164.12 | 129.9 |
| auto | 578966.65 | 4140 | 139.85 | 84.9 |
| toys | 471286.48 | 4030 | 116.94 | 79.9 |

</div>

The category with highest revenue is health_beauty 1233131.72 BRL and 9465 items. Watches & gifts has the second highest revenue with much less items sold. That is because their average price is very high. In every top 10 category the average price is higher than the median price.

### Categories & prices

### Regional markets

### Delivery & satisfaction

### Pricing & sellers

## Looker Studio Dashboard
Full Looker Studio Dashboard is available at the [Dashboard](dashboard)

## Data source
[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

## Tools
- BigQuery
- Looker studio

## Author
Bartosz Malinowski
