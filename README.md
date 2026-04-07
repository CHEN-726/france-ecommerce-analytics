# Analyse de la performance d’un e-commerce D2C en France

A France-focused e-commerce analytics project designed for **Data Analyst / Business Analyst** roles.  
This project simulates a French D2C brand operating across major cities such as **Paris, Lyon, Marseille, Lille, Toulouse, Bordeaux, Nantes, Strasbourg, Montpellier, and Nice**.

The objective is not only to build dashboards, but to answer real business questions around **growth, conversion, customer value, and market prioritisation**.

---

## 1. Business Context

A French D2C e-commerce brand wants to better understand its performance across major urban markets in France.

Management is looking for answers to the following questions:

- Which cities are true growth engines, and which ones are underperforming?
- Where does the customer funnel leak the most?
- Which customer segments deserve priority CRM and retention actions?
- Which product categories drive revenue versus traffic only?
- How should resources and budget be allocated in the next quarter?

This project was built to simulate the work of a **Data Analyst / Business Analyst alternant** supporting management with structured insights and actionable recommendations.

---

## 2. Project Objectives

This project aims to:

- Build a France-focused e-commerce dataset with realistic business logic
- Analyze performance at **city, customer, funnel, and category** level
- Create an **executive dashboard** for management
- Deliver a **data-driven action plan** that a business leader could actually use

---

## 3. Key Business Questions

### Executive / Management Level
1. Which French cities generate the most revenue and which ones show the strongest efficiency?
2. Is growth driven by volume, better conversion, or higher basket value?
3. Where are we under target and why?

### Customer & Conversion Level
4. At which stage do users drop out of the funnel?
5. How do conversion patterns differ by city, device, and acquisition channel?
6. Which users are most valuable and which ones are at risk?

### Product / Market Level
7. Which categories are true revenue drivers?
8. Which category-city combinations should receive more support?
9. How should the business prioritise actions over the next 30 / 60 / 90 days?

---

## 4. Dataset Overview

This project uses a **synthetic but business-realistic dataset** built specifically for a French market scenario.

### Core tables
- `dim_users`
- `dim_products`
- `dim_city_fr`
- `fact_events`
- `fact_orders`
- `dim_targets_monthly`

### Main business dimensions
- French cities
- product categories
- acquisition channels
- device types
- customer lifecycle
- targets vs actuals

### Scope
- Geography: France
- Main cities: Paris, Lyon, Marseille, Lille, Toulouse, Bordeaux, Nantes, Strasbourg, Montpellier, Nice
- Time range: 12 months
- Business model: D2C e-commerce / retail

---

## 5. Methodology

The project follows a structured business analytics workflow:

### Step 1 — Data Design
A realistic e-commerce data model was designed around:
- users
- products
- cities
- events
- orders
- monthly business targets

### Step 2 — Data Quality Checks
Before analysis, the dataset is validated for:
- null values
- duplicates
- broken joins
- invalid revenue values
- consistency between events and orders

### Step 3 — KPI Framework
The KPI system was built at three levels:

#### Executive KPIs
- Revenue
- Orders
- Unique Buyers
- Conversion Rate
- Average Order Value (AOV)
- Repeat Purchase Rate
- Revenue vs Target

#### City KPIs
- Revenue by city
- Growth by city
- AOV by city
- Conversion by city
- Revenue share
- Market prioritisation

#### Customer KPIs
- Funnel conversion
- New vs Returning users
- RFM segmentation
- Revenue share by customer segment

### Step 4 — Analysis
The project is structured from high level to detailed diagnosis:
1. Executive overview
2. City and category performance
3. Funnel diagnosis
4. Customer segmentation
5. Strategic recommendations

---

## 6. Main Analysis Modules

### 1. Executive Overview
A top-management view of overall business health:
- revenue trend
- orders
- buyers
- AOV
- conversion
- target attainment

### 2. City Performance Analysis
A market-level analysis to identify:
- high-growth cities
- inefficient markets
- strong vs weak conversion zones
- city-level revenue opportunities

### 3. Funnel Analysis
A diagnosis of user behavior across:
- View
- Favorite
- Add to Cart
- Purchase

This helps identify where the business loses the most value.

### 4. Customer Segmentation
A customer-level analysis based on:
- Recency
- Frequency
- Monetary value

The objective is to identify:
- Champions
- Loyal Customers
- Potential Loyalists
- One-time Buyers
- At-risk Customers

### 5. Category & Market Mix
A business-oriented view of:
- revenue-driving categories
- traffic-heavy but low-conversion categories
- city-category opportunities

---

## 7. Tools Used

- **Python** — synthetic data generation and validation
- **SQL** — business analysis and KPI extraction
- **Tableau** — dashboarding and executive reporting
- **GitHub** — project documentation and portfolio presentation

---

## 8. Repository Structure

```text
france-ecommerce-analytics/
├── README.md
├── data/
│   ├── raw/
│   └── processed/
├── sql/
│   ├── 01_data_quality.sql
│   ├── 02_exec_overview.sql
│   ├── 03_city_market_analysis.sql
│   ├── 04_funnel_conversion.sql
│   ├── 05_rfm_segmentation.sql
│   ├── 06_category_mix.sql
│   └── 07_targets_vs_actuals.sql
├── notebooks/
│   ├── 01_generate_data.ipynb
│   ├── 02_validation_checks.ipynb
│   └── 03_metric_validation.ipynb
├── dashboard/
│   ├── tableau/
│   └── screenshots/
├── reports/
│   ├── executive_summary.pdf
│   └── full_report.pdf
└── docs/
    ├── data_dictionary.md
    ├── methodology.md
    ├── business_questions.md
    └── metric_definitions.md
