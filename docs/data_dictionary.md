# Data Dictionary

This document describes the structure, business meaning and intended usage of the main tables used in this project.

## Project Scope

This project simulates a France-focused D2C e-commerce business operating across major cities including:

- Paris
- Lyon
- Marseille
- Lille
- Toulouse
- Bordeaux
- Nantes
- Strasbourg
- Montpellier
- Nice

The data model is designed to support business analysis across:

- executive performance
- city performance
- customer funnel
- customer segmentation
- product/category mix
- target vs actual analysis

---

# 1. `dim_users`

**Granularity:** one row per user  
**Primary key:** `user_id`

| Column | Type | Description |
|---|---|---|
| user_id | string | Unique user identifier |
| signup_date | date | Date when the user first registered |
| first_city_code | string | First associated city of the user |
| acquisition_channel | string | Main acquisition source (`Organic`, `Paid Social`, `Search`, `Email`, `Referral`, `Influencer`) |
| device_preference | string | Preferred device type (`Mobile`, `Desktop`, `Tablet`) |
| loyalty_member_flag | integer / boolean | Indicates whether the user is part of the loyalty program |
| first_order_date | date | Date of the first purchase, if any |
| customer_type | string | Customer profile (`Prospect`, `One-time Buyer`, `Repeat Buyer`, `Loyal Customer`) |
| preferred_category | string | Preferred product category |

**Business role:**  
Used for customer profiling, segmentation, cohort analysis, CRM logic and channel-quality comparison.

---

# 2. `dim_products`

**Granularity:** one row per SKU  
**Primary key:** `product_id`

| Column | Type | Description |
|---|---|---|
| product_id | string | Unique product identifier |
| product_name | string | Product name |
| category | string | Main category (`Skincare`, `Haircare`, `Bodycare`, `Fragrance`, `Makeup`, `Gift Set`) |
| subcategory | string | Product subcategory |
| base_price | decimal | Standard listed product price |
| price_band | string | Price segment (`Entry`, `Mid`, `Premium`) |
| is_core_product | integer / boolean | Indicates whether the product is a core evergreen SKU |
| is_seasonal | integer / boolean | Indicates whether the product is highly seasonal |
| launch_month | integer | Product launch month |

**Business role:**  
Used for category analysis, revenue mix analysis, seasonal analysis and product portfolio diagnosis.

---

# 3. `dim_city_fr`

**Granularity:** one row per city  
**Primary key:** `city_code`

| Column | Type | Description |
|---|---|---|
| city_code | string | Unique city code (`PAR`, `LYO`, `MAR`, etc.) |
| city_name | string | City name |
| region_name | string | French region name |
| market_tier | string | Market tier (`Tier 1`, `Tier 2`, `Tier 3`) |
| store_presence_flag | integer / boolean | Indicates whether a store / showroom exists in the city |
| priority_market_flag | integer / boolean | Indicates whether management considers this city a priority market |
| city_profile | string | Qualitative market description |

**Business role:**  
Used for market prioritisation, regional analysis, local growth comparison and city-level action planning.

---

# 4. `fact_events`

**Granularity:** one row per user event  
**Primary key:** `event_id`

**Foreign keys:**
- `user_id` → `dim_users.user_id`
- `product_id` → `dim_products.product_id`
- `city_code` → `dim_city_fr.city_code`

| Column | Type | Description |
|---|---|---|
| event_id | string | Unique event identifier |
| user_id | string | User associated with the event |
| session_id | string | Session identifier |
| event_time | timestamp | Timestamp of the event |
| event_date | date | Event date |
| event_hour | integer | Event hour |
| event_type | string | Event type (`view`, `favorite`, `add_to_cart`, `purchase`) |
| product_id | string | Product associated with the event |
| city_code | string | City associated with the event |
| device_type | string | Device used in the session |
| channel | string | Session-level acquisition / traffic source |
| is_weekend | integer / boolean | Indicates whether the event happened on a weekend |
| is_promo_day | integer / boolean | Indicates whether the event occurred during a promotion day |
| new_vs_returning | string | Indicates whether the user is new or returning |

**Business role:**  
Used for funnel analysis, behavior analysis, traffic diagnosis, session analysis and conversion breakdown by city / channel / device.

---

# 5. `fact_orders`

**Granularity:** one row per order line  
**Primary key:** `order_line_id`

**Foreign keys:**
- `user_id` → `dim_users.user_id`
- `product_id` → `dim_products.product_id`
- `city_code` → `dim_city_fr.city_code`

| Column | Type | Description |
|---|---|---|
| order_line_id | string | Unique order line identifier |
| order_id | string | Order identifier |
| user_id | string | Purchasing user |
| order_date | date | Order date |
| order_time | timestamp | Order timestamp |
| city_code | string | Associated city |
| product_id | string | Purchased product |
| quantity | integer | Quantity ordered |
| unit_price | decimal | Unit selling price |
| discount_amount | decimal | Discount applied at line level |
| net_revenue | decimal | Net revenue after discount |
| is_first_order | integer / boolean | Indicates whether the order belongs to the user’s first purchase |
| payment_type | string | Payment method (`Card`, `PayPal`, `Mobile Wallet`) |
| delivery_type | string | Delivery type (`Standard`, `Express`, `Pickup Point`) |
| customer_order_type | string | Purchase type (`First-time`, `Repeat`) |

**Business role:**  
Used for revenue analysis, AOV analysis, repeat purchase analysis, customer value analysis and actual-vs-target reporting.

---

# 6. `dim_targets_monthly`

**Granularity:** one row per city × month × category  
**Composite key:** `target_month + city_code + category`

**Foreign keys:**
- `city_code` → `dim_city_fr.city_code`
- `category` → `dim_products.category`

| Column | Type | Description |
|---|---|---|
| target_month | date | Month reference (first day of the month) |
| city_code | string | Associated city |
| category | string | Product category |
| target_revenue | decimal | Monthly target revenue |
| target_orders | integer | Monthly target order count |
| target_buyers | integer | Monthly target buyer count |
| priority_focus_flag | integer / boolean | Indicates whether the market/category is a strategic focus for the month |

**Business role:**  
Used for target attainment analysis, management reporting and strategic prioritisation by market and category.

---

# Data Model Summary

## Main dimensions
- users
- products
- cities
- monthly targets

## Main facts
- events
- orders

## Core business logic supported
- executive KPI reporting
- market prioritisation
- conversion funnel analysis
- new vs returning customer analysis
- customer value / RFM segmentation
- target vs actual performance monitoring

---

# Notes

- This dataset is synthetic but designed to follow realistic business logic.
- The objective is not only technical analysis, but also decision-oriented business storytelling.
- The structure was intentionally designed to support a management-friendly dashboard and strategic recommendations.

