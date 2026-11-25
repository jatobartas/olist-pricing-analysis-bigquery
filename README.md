# Analysis of an E-commerce Marketplace Olist with BigQuery & Looker Studio

## Introduction
This project analyses data of Brazilian E-Commerce website Olist using BigQuery and Looker Studio. The main goal of the analysis is to draw some insights from the Data and to create specific business recomendations depending on the outcome. The focus is put on understanding the market sells, prices (across categories), sales (across regions), delivery time, freight cost and customer satisfaction.

## Analysis (BigQuery & Looker Studio)

### Data Check

This part of project is dedicated for the check of the quality of 9 tables that are included in the Dataset (from Kaggle). The process is conducted in BigQuery and is carried out to ensure the quality of the analysis. The full code is available in [`sql/01_data_check.sql`](sql/01_data_check.sql).

0.1 Row counts
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
### Cleaning

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
