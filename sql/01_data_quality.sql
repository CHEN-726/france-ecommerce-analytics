-- 01_data_quality.sql
-- France e-commerce analytics project
-- Objective: validate the structure and consistency of the dataset before analysis

-- 1. Row count by table
SELECT 'dim_users' AS table_name, COUNT(*) AS row_count FROM dim_users
UNION ALL
SELECT 'dim_products', COUNT(*) FROM dim_products
UNION ALL
SELECT 'dim_city_fr', COUNT(*) FROM dim_city_fr
UNION ALL
SELECT 'fact_events', COUNT(*) FROM fact_events
UNION ALL
SELECT 'fact_orders', COUNT(*) FROM fact_orders
UNION ALL
SELECT 'dim_targets_monthly', COUNT(*) FROM dim_targets_monthly;

-- 2. Check nulls in key columns
SELECT
  SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user_id,
  SUM(CASE WHEN signup_date IS NULL THEN 1 ELSE 0 END) AS null_signup_date,
  SUM(CASE WHEN first_city_code IS NULL THEN 1 ELSE 0 END) AS null_first_city_code
FROM dim_users;

SELECT
  SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
  SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS null_category
FROM dim_products;

SELECT
  SUM(CASE WHEN event_id IS NULL THEN 1 ELSE 0 END) AS null_event_id,
  SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user_id,
  SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
  SUM(CASE WHEN city_code IS NULL THEN 1 ELSE 0 END) AS null_city_code,
  SUM(CASE WHEN event_type IS NULL THEN 1 ELSE 0 END) AS null_event_type
FROM fact_events;

SELECT
  SUM(CASE WHEN order_line_id IS NULL THEN 1 ELSE 0 END) AS null_order_line_id,
  SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
  SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user_id,
  SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
  SUM(CASE WHEN city_code IS NULL THEN 1 ELSE 0 END) AS null_city_code
FROM fact_orders;
