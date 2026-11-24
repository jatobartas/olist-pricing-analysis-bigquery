# Analysis of an E-commerce Marketplace Olist with BigQuery & Looker Studio

## Overview
This project analyses data of Brazilian E-Commerce website Olist using BigQuery and Looker Studio. The main goal of the analysis is to draw some insights from the Data and to create specific business recomendations depending on the outcome. The focus is put on understanding the market sells, prices across categories, sales across regions, delivery time, freight cost and customer satisfaction.

## Analysis (BigQuery & Looker Studio)
### Data Audit

This part of project is dedicated for the check of the quality of 9 tables that are included in the Dataset (from Kaggle). The process is conducted in BigQuery and is carried out to ensure the quality of the analysis. The full code is available in [`sql/01_data_audit.sql`](sql/01_data_audit.sql).

### Olist - overview
![01_overview](dashboard/screenshots/01_overview.png)
### Categories & prices
![02_categories_prices](dashboard/screenshots/02_categories_prices.png)
### Regional markets
![03_regional_markets](dashboard/screenshots/03_regional_markets.png)
### Delivery & satisfaction
![04_delivery_satisfaction](dashboard/screenshots/04_delivery_satisfaction.png)
### Pricing & sellers
![05_pricing_sellers](dashboard/screenshots/05_pricing_sellers.png)
### Additional
![06_additional](dashboard/screenshots/06_additional.png)

## Looker Studio Dashboard
Full Looker Studio Dashboard is available at the [Dashboard](dashboard)
## Data source
[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

## Tools
- BigQuery
- Looker studio

## Author
Bartosz Malinowski
