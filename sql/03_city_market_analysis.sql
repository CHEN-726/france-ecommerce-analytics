-- 03_city_market_analysis.sql
-- France e-commerce analytics project
-- Objective: evaluate city-level business performance and identify priority markets

-- 1. Core city performance table
WITH city_orders AS (
  SELECT
    o.city_code,
    SUM(o.net_revenue) AS city_revenue,
    COUNT(DISTINCT o.order_id) AS city_orders,
    COUNT(DISTINCT o.user_id) AS city_buyers,
    ROUND(SUM(o.net_revenue) * 1.0 / COUNT(DISTINCT o.order_id), 2) AS city_aov
  FROM fact_orders o
  GROUP BY o.city_code
),
city_views AS (
  SELECT
    e.city_code,
    COUNT(DISTINCT CASE WHEN e.event_type = 'view' THEN e.user_id END) AS city_viewers
  FROM fact_events e
  GROUP BY e.city_code
)
SELECT
  c.city_name,
  c.region_name,
  c.market_tier,
  c.store_presence_flag,
  c.priority_market_flag,
  co.city_revenue,
  co.city_orders,
  co.city_buyers,
  co.city_aov,
  cv.city_viewers,
  ROUND(co.city_buyers * 1.0 / NULLIF(cv.city_viewers, 0), 4) AS city_conversion_rate
FROM dim_city_fr c
LEFT JOIN city_orders co
  ON c.city_code = co.city_code
LEFT JOIN city_views cv
  ON c.city_code = cv.city_code
ORDER BY co.city_revenue DESC;

-- 2. City revenue share
WITH city_revenue AS (
  SELECT
    city_code,
    SUM(net_revenue) AS revenue
  FROM fact_orders
  GROUP BY city_code
),
total_revenue AS (
  SELECT SUM(net_revenue) AS total_revenue
  FROM fact_orders
)
SELECT
  c.city_name,
  cr.revenue,
  ROUND(cr.revenue * 1.0 / tr.total_revenue, 4) AS revenue_share
FROM city_revenue cr
CROSS JOIN total_revenue tr
LEFT JOIN dim_city_fr c
  ON cr.city_code = c.city_code
ORDER BY cr.revenue DESC;

-- 3. Monthly revenue by city
SELECT
  DATE_TRUNC('month', o.order_date) AS order_month,
  c.city_name,
  SUM(o.net_revenue) AS monthly_revenue,
  COUNT(DISTINCT o.order_id) AS monthly_orders,
  COUNT(DISTINCT o.user_id) AS monthly_buyers
FROM fact_orders o
LEFT JOIN dim_city_fr c
  ON o.city_code = c.city_code
GROUP BY 1, 2
ORDER BY 1, monthly_revenue DESC;

-- 4. Revenue by city and category
SELECT
  c.city_name,
  p.category,
  SUM(o.net_revenue) AS revenue,
  COUNT(DISTINCT o.order_id) AS orders,
  COUNT(DISTINCT o.user_id) AS buyers
FROM fact_orders o
LEFT JOIN dim_city_fr c
  ON o.city_code = c.city_code
LEFT JOIN dim_products p
  ON o.product_id = p.product_id
GROUP BY 1, 2
ORDER BY c.city_name, revenue DESC;

-- 5. City target attainment
WITH city_actuals AS (
  SELECT
    DATE_TRUNC('month', o.order_date) AS target_month,
    o.city_code,
    SUM(o.net_revenue) AS actual_revenue
  FROM fact_orders o
  GROUP BY 1, 2
),
city_targets AS (
  SELECT
    target_month,
    city_code,
    SUM(target_revenue) AS target_revenue
  FROM dim_targets_monthly
  GROUP BY 1, 2
)
SELECT
  ct.target_month,
  c.city_name,
  ct.target_revenue,
  COALESCE(ca.actual_revenue, 0) AS actual_revenue,
  COALESCE(ca.actual_revenue, 0) - ct.target_revenue AS revenue_gap,
  ROUND(COALESCE(ca.actual_revenue, 0) * 1.0 / NULLIF(ct.target_revenue, 0), 4) AS target_attainment
FROM city_targets ct
LEFT JOIN city_actuals ca
  ON ct.target_month = ca.target_month
 AND ct.city_code = ca.city_code
LEFT JOIN dim_city_fr c
  ON ct.city_code = c.city_code
ORDER BY ct.target_month, c.city_name;

-- 6. City ranking by efficiency
WITH city_orders AS (
  SELECT
    o.city_code,
    SUM(o.net_revenue) AS city_revenue,
    COUNT(DISTINCT o.order_id) AS city_orders,
    COUNT(DISTINCT o.user_id) AS city_buyers,
    ROUND(SUM(o.net_revenue) * 1.0 / COUNT(DISTINCT o.order_id), 2) AS city_aov
  FROM fact_orders o
  GROUP BY o.city_code
),
city_views AS (
  SELECT
    e.city_code,
    COUNT(DISTINCT CASE WHEN e.event_type = 'view' THEN e.user_id END) AS city_viewers
  FROM fact_events e
  GROUP BY e.city_code
)
SELECT
  c.city_name,
  co.city_revenue,
  co.city_orders,
  co.city_buyers,
  co.city_aov,
  cv.city_viewers,
  ROUND(co.city_buyers * 1.0 / NULLIF(cv.city_viewers, 0), 4) AS city_conversion_rate,
  ROUND(co.city_revenue * 1.0 / NULLIF(co.city_buyers, 0), 2) AS revenue_per_buyer
FROM dim_city_fr c
LEFT JOIN city_orders co
  ON c.city_code = co.city_code
LEFT JOIN city_views cv
  ON c.city_code = cv.city_code
ORDER BY city_conversion_rate DESC, revenue_per_buyer DESC;

-- 7. Optional city diagnosis labels
WITH city_orders AS (
  SELECT
    o.city_code,
    SUM(o.net_revenue) AS city_revenue
  FROM fact_orders o
  GROUP BY o.city_code
),
city_growth AS (
  SELECT
    DATE_TRUNC('month', o.order_date) AS order_month,
    o.city_code,
    SUM(o.net_revenue) AS monthly_revenue
  FROM fact_orders o
  GROUP BY 1, 2
),
latest_month AS (
  SELECT MAX(DATE_TRUNC('month', order_date)) AS latest_month
  FROM fact_orders
),
previous_month AS (
  SELECT DATEADD('month', -1, latest_month) AS prev_month
  FROM latest_month
),
growth_compare AS (
  SELECT
    g.city_code,
    SUM(CASE WHEN g.order_month = lm.latest_month THEN g.monthly_revenue ELSE 0 END) AS latest_revenue,
    SUM(CASE WHEN g.order_month = pm.prev_month THEN g.monthly_revenue ELSE 0 END) AS previous_revenue
  FROM city_growth g
  CROSS JOIN latest_month lm
  CROSS JOIN previous_month pm
  GROUP BY g.city_code
)
SELECT
  c.city_name,
  gc.latest_revenue,
  gc.previous_revenue,
  ROUND(
    (gc.latest_revenue - gc.previous_revenue) * 1.0 / NULLIF(gc.previous_revenue, 0),
    4
  ) AS month_growth_rate
FROM growth_compare gc
LEFT JOIN dim_city_fr c
  ON gc.city_code = c.city_code
ORDER BY month_growth_rate DESC;
