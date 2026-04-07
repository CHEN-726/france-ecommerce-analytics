-- 02_exec_overview.sql
-- France e-commerce analytics project
-- Objective: build the main executive KPIs for management reporting

-- 1. Overall business performance
SELECT
  SUM(net_revenue) AS total_revenue,
  COUNT(DISTINCT order_id) AS total_orders,
  COUNT(DISTINCT user_id) AS total_buyers,
  ROUND(SUM(net_revenue) * 1.0 / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM fact_orders;

-- 2. Monthly revenue trend
SELECT
  DATE_TRUNC('month', order_date) AS order_month,
  SUM(net_revenue) AS monthly_revenue,
  COUNT(DISTINCT order_id) AS monthly_orders,
  COUNT(DISTINCT user_id) AS monthly_buyers,
  ROUND(SUM(net_revenue) * 1.0 / COUNT(DISTINCT order_id), 2) AS monthly_aov
FROM fact_orders
GROUP BY 1
ORDER BY 1;

-- 3. Monthly conversion overview
WITH monthly_views AS (
  SELECT
    DATE_TRUNC('month', event_date) AS event_month,
    COUNT(DISTINCT user_id) AS viewers
  FROM fact_events
  WHERE event_type = 'view'
  GROUP BY 1
),
monthly_buyers AS (
  SELECT
    DATE_TRUNC('month', order_date) AS order_month,
    COUNT(DISTINCT user_id) AS buyers
  FROM fact_orders
  GROUP BY 1
)
SELECT
  v.event_month,
  v.viewers,
  b.buyers,
  ROUND(b.buyers * 1.0 / NULLIF(v.viewers, 0), 4) AS buyer_conversion_rate
FROM monthly_views v
LEFT JOIN monthly_buyers b
  ON v.event_month = b.order_month
ORDER BY v.event_month;

-- 4. Revenue by city
SELECT
  c.city_name,
  SUM(o.net_revenue) AS city_revenue,
  COUNT(DISTINCT o.order_id) AS city_orders,
  COUNT(DISTINCT o.user_id) AS city_buyers,
  ROUND(SUM(o.net_revenue) * 1.0 / COUNT(DISTINCT o.order_id), 2) AS city_aov
FROM fact_orders o
LEFT JOIN dim_city_fr c
  ON o.city_code = c.city_code
GROUP BY c.city_name
ORDER BY city_revenue DESC;

-- 5. Revenue by category
SELECT
  p.category,
  SUM(o.net_revenue) AS category_revenue,
  COUNT(DISTINCT o.order_id) AS category_orders,
  COUNT(DISTINCT o.user_id) AS category_buyers,
  ROUND(SUM(o.net_revenue) * 1.0 / COUNT(DISTINCT o.order_id), 2) AS category_aov
FROM fact_orders o
LEFT JOIN dim_products p
  ON o.product_id = p.product_id
GROUP BY p.category
ORDER BY category_revenue DESC;

-- 6. Revenue vs target by month
WITH actuals AS (
  SELECT
    DATE_TRUNC('month', o.order_date) AS target_month,
    p.category,
    o.city_code,
    SUM(o.net_revenue) AS actual_revenue
  FROM fact_orders o
  LEFT JOIN dim_products p
    ON o.product_id = p.product_id
  GROUP BY 1, 2, 3
)
SELECT
  t.target_month,
  c.city_name,
  t.category,
  t.target_revenue,
  COALESCE(a.actual_revenue, 0) AS actual_revenue,
  COALESCE(a.actual_revenue, 0) - t.target_revenue AS revenue_gap,
  ROUND(COALESCE(a.actual_revenue, 0) * 1.0 / NULLIF(t.target_revenue, 0), 4) AS target_attainment
FROM dim_targets_monthly t
LEFT JOIN actuals a
  ON t.target_month = a.target_month
 AND t.city_code = a.city_code
 AND t.category = a.category
LEFT JOIN dim_city_fr c
  ON t.city_code = c.city_code
ORDER BY t.target_month, c.city_name, t.category;

-- 7. Repeat purchase rate
WITH customer_orders AS (
  SELECT
    user_id,
    COUNT(DISTINCT order_id) AS order_count
  FROM fact_orders
  GROUP BY user_id
)
SELECT
  COUNT(*) AS total_buyers,
  SUM(CASE WHEN order_count >= 2 THEN 1 ELSE 0 END) AS repeat_buyers,
  ROUND(
    SUM(CASE WHEN order_count >= 2 THEN 1 ELSE 0 END) * 1.0 / COUNT(*),
    4
  ) AS repeat_purchase_rate
FROM customer_orders;
