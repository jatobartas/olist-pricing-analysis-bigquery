# Analysis of an E-commerce Marketplace Olist with BigQuery & Looker Studio

## Introduction
This project analyses data of Brazilian E-Commerce website Olist using BigQuery and Looker Studio. The main goal of the analysis is to draw some insights from the Data and to create specific business recomendations depending on the outcome. The focus is put on understanding the market sells, prices (across categories), sales (across regions), delivery time, freight cost and customer satisfaction.

## Analysis (BigQuery & Looker Studio)

### Data Check

This part of project is dedicated for the check of the quality of 9 tables that are included in the Dataset (from Kaggle). The process is conducted in BigQuery and is carried out to ensure the quality of the analysis. The full code is available in [`sql/01_data_check.sql`](sql/01_data_check.sql).

1. **Row counts** - to get to know the data and see with how big dataset will I be working with. All CSV tables were loaded correctly. 

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

2. **Tables preview** - to see the column names and example data across different tables. The example query outcome is showed below.

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

3. **Check of distinct keys** - to see if the keys are unique so joining the tables would be safe and not duplicate the rows.

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

4. **Missing data in the most important columns** - missing values decide which rows can be used - we can't calculate the average delivery date for rows without delivery time.

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

5. **Check of order statuses and their share in the data + date range** - to check how many orders we're delivered (and their other statuses). Also to check what is the timestamp.
   
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

6. **Price and freight check (min/max, average, median, zero values)** - to see the range of prices and freight costs and to spot extreme or zero values before calculating averages and medians.

<div align="center">

| items | min_price | max_price | avg_price | median_price | p99_price | min_freight | max_freight | avg_freight | zero_freight |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 112650 | 0.85 | 6735.0 | 120.65 | 74.99 | 890.0 | 0.0 | 409.68 | 19.99 | 383 |

</div>

Item prices vary from 0.85 BRL to 6735 BRL. Average price is 120.65, median is 74.99 (Median is smaller than the average so it implies right-skeweness of the distribution - most of the products have smaller prices but some of them have much higher and that's why mean chases the tail and ends up higher than the median). The freight varies from 0 to 409.68 BRL and it's average is 20 BRL. Amount of orders with zero freight - 383.

7. **Check if the dates are consistent and if there are any errors (orders without a date or delivered before they were purchased)**

<div align="center">

| delivered_without_date | delivered_before_purchase |
|:---:|:---:|
| 8 | 0 |

</div>

Eight of the orders were delivered without a delivery date and 0 were delivered before purchase - everything works.

### Cleaning
1. **Reviews made to be one row per order** - The data check in 1.3 showed that some of the orders have more than one review. Joining reviews directly to order items would duplicate those items and inflate revenue and item counts. A view reviews_per_order was created with the average score per order. After this every order has at maximum one review - it can be joined safely now.
2. **Creation of one big table containing everything necessary for the analysis (big_table)** - a single table will be used for all the analysis queries. It was built step by step by joining: order_items + orders (purchase dates and delivery dates) + customers (customer_unique_id, customer state and city) + sellers (seller state and city) + reviews_per_order + products + category_translation (review score and product category). For the first join (items and orders) INNER JOIN was used to get only these rows that occur in both of the tables. For the rest (after having items and their orders) we join the rest with LEFT JOIN, so that we have everything that is in the base table and only those rows that are shared in this and the other tables.
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

3. **Validation (check if big_table was created properly, if any data was lost and no rows are duplicated)**
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

4. **Summary (missing values in big_table)**
Eight items have no delivery_days. The average and median ignore NULL so we leave them as they are. Filling in 0 would artificially lower the average delivery days. 827 items have no review score - no review doesn't mean a score of 0 so nothing is filled in. 1537 items are with a category 'unknown'. They are left here so the total analysis stays complete.

### Overview

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
