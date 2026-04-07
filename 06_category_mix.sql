-- 06_category_mix.sql
-- France e-commerce analytics project
-- Objective: analyse category contribution, traffic vs revenue, and city-category mix

-- 1. Core category performance
SELECT
  p.category,
  ROUND(SUM(o.net_revenue), 2) AS category_revenue,
  COUNT(DISTINCT o.order_id) AS category_orders,
  COUNT(DISTINCT o.user_id) AS category_buyers,
  ROUND(SUM(o.net_revenue) * 1.0 / COUNT(DISTINCT o.order_id), 2) AS category_aov,
  ROUND(SUM(o.net_revenue) * 1.0 / COUNT(DISTINCT o.user_id), 2) AS revenue_per_buyer
FROM fact_orders o
LEFT JOIN dim_products p
  ON o.product_id = p.product_id
GROUP BY p.category
ORDER BY category_revenue DESC;

-- 2. Category revenue share
WITH category_revenue AS (
  SELECT
    p.category,
    SUM(o.net_revenue) AS revenue
  FROM fact_orders o
  LEFT JOIN dim_products p
    ON o.product_id = p.product_id
  GROUP BY p.category
),
total_revenue AS (
  SELECT SUM(net_revenue) AS total_revenue
  FROM fact_orders
)
SELECT
  cr.category,
  ROUND(cr.revenue, 2) AS revenue,
  ROUND(cr.revenue * 1.0 / NULLIF(tr.total_revenue, 0), 4) AS revenue_share
FROM category_revenue cr
CROSS JOIN total_revenue tr
ORDER BY revenue DESC;

-- 3. Monthly category revenue trend
SELECT
  DATE_TRUNC('month', o.order_date) AS order_month,
  p.category,
  ROUND(SUM(o.net_revenue), 2) AS monthly_revenue,
  COUNT(DISTINCT o.order_id) AS monthly_orders,
  COUNT(DISTINCT o.user_id) AS monthly_buyers
FROM fact_orders o
LEFT JOIN dim_products p
  ON o.product_id = p.product_id
GROUP BY 1, 2
ORDER BY 1, monthly_revenue DESC;

-- 4. Category performance by city
SELECT
  c.city_name,
  p.category,
  ROUND(SUM(o.net_revenue), 2) AS revenue,
  COUNT(DISTINCT o.order_id) AS orders,
  COUNT(DISTINCT o.user_id) AS buyers,
  ROUND(SUM(o.net_revenue) * 1.0 / COUNT(DISTINCT o.order_id), 2) AS aov
FROM fact_orders o
LEFT JOIN dim_city_fr c
  ON o.city_code = c.city_code
LEFT JOIN dim_products p
  ON o.product_id = p.product_id
GROUP BY c.city_name, p.category
ORDER BY c.city_name, revenue DESC;

-- 5. Category traffic (views) vs revenue
WITH category_views AS (
  SELECT
    p.category,
    COUNT(*) AS total_views,
    COUNT(DISTINCT e.user_id) AS viewing_users
  FROM fact_events e
  LEFT JOIN dim_products p
    ON e.product_id = p.product_id
  WHERE e.event_type = 'view'
  GROUP BY p.category
),
category_revenue AS (
  SELECT
    p.category,
    ROUND(SUM(o.net_revenue), 2) AS revenue,
    COUNT(DISTINCT o.user_id) AS buyers
  FROM fact_orders o
  LEFT JOIN dim_products p
    ON o.product_id = p.product_id
  GROUP BY p.category
)
SELECT
  v.category,
  v.total_views,
  v.viewing_users,
  COALESCE(r.revenue, 0) AS revenue,
  COALESCE(r.buyers, 0) AS buyers,
  ROUND(COALESCE(r.revenue, 0) * 1.0 / NULLIF(v.total_views, 0), 4) AS revenue_per_view,
  ROUND(COALESCE(r.buyers, 0) * 1.0 / NULLIF(v.viewing_users, 0), 4) AS buyer_per_viewer_rate
FROM category_views v
LEFT JOIN category_revenue r
  ON v.category = r.category
ORDER BY revenue DESC;

-- 6. Category conversion funnel
SELECT
  p.category,
  COUNT(DISTINCT CASE WHEN e.event_type = 'view' THEN e.user_id END) AS view_users,
  COUNT(DISTINCT CASE WHEN e.event_type = 'favorite' THEN e.user_id END) AS favorite_users,
  COUNT(DISTINCT CASE WHEN e.event_type = 'add_to_cart' THEN e.user_id END) AS cart_users,
  COUNT(DISTINCT CASE WHEN e.event_type = 'purchase' THEN e.user_id END) AS purchase_users,
  ROUND(
    COUNT(DISTINCT CASE WHEN e.event_type = 'purchase' THEN e.user_id END) * 1.0
    / NULLIF(COUNT(DISTINCT CASE WHEN e.event_type = 'view' THEN e.user_id END), 0),
    4
  ) AS view_to_purchase_rate,
  ROUND(
    COUNT(DISTINCT CASE WHEN e.event_type = 'purchase' THEN e.user_id END) * 1.0
    / NULLIF(COUNT(DISTINCT CASE WHEN e.event_type = 'add_to_cart' THEN e.user_id END), 0),
    4
  ) AS cart_to_purchase_rate
FROM fact_events e
LEFT JOIN dim_products p
  ON e.product_id = p.product_id
GROUP BY p.category
ORDER BY purchase_users DESC;

-- 7. Top categories by city share
WITH city_category_revenue AS (
  SELECT
    o.city_code,
    p.category,
    SUM(o.net_revenue) AS revenue
  FROM fact_orders o
  LEFT JOIN dim_products p
    ON o.product_id = p.product_id
  GROUP BY o.city_code, p.category
),
city_total_revenue AS (
  SELECT
    city_code,
    SUM(net_revenue) AS total_revenue
  FROM fact_orders
  GROUP BY city_code
)
SELECT
  c.city_name,
  ccr.category,
  ROUND(ccr.revenue, 2) AS revenue,
  ROUND(ccr.revenue * 1.0 / NULLIF(ctr.total_revenue, 0), 4) AS category_share_in_city
FROM city_category_revenue ccr
LEFT JOIN city_total_revenue ctr
  ON ccr.city_code = ctr.city_code
LEFT JOIN dim_city_fr c
  ON ccr.city_code = c.city_code
ORDER BY c.city_name, category_share_in_city DESC;

-- 8. Category target attainment
WITH actuals AS (
  SELECT
    DATE_TRUNC('month', o.order_date) AS target_month,
    o.city_code,
    p.category,
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
  ROUND(t.target_revenue, 2) AS target_revenue,
  ROUND(COALESCE(a.actual_revenue, 0), 2) AS actual_revenue,
  ROUND(COALESCE(a.actual_revenue, 0) - t.target_revenue, 2) AS revenue_gap,
  ROUND(COALESCE(a.actual_revenue, 0) * 1.0 / NULLIF(t.target_revenue, 0), 4) AS target_attainment
FROM dim_targets_monthly t
LEFT JOIN actuals a
  ON t.target_month = a.target_month
 AND t.city_code = a.city_code
 AND t.category = a.category
LEFT JOIN dim_city_fr c
  ON t.city_code = c.city_code
ORDER BY t.target_month, c.city_name, t.category;

-- 9. Category opportunity diagnosis
WITH category_views AS (
  SELECT
    p.category,
    COUNT(*) AS total_views,
    COUNT(DISTINCT e.user_id) AS viewing_users
  FROM fact_events e
  LEFT JOIN dim_products p
    ON e.product_id = p.product_id
  WHERE e.event_type = 'view'
  GROUP BY p.category
),
category_revenue AS (
  SELECT
    p.category,
    SUM(o.net_revenue) AS revenue,
    COUNT(DISTINCT o.user_id) AS buyers
  FROM fact_orders o
  LEFT JOIN dim_products p
    ON o.product_id = p.product_id
  GROUP BY p.category
)
SELECT
  v.category,
  v.total_views,
  v.viewing_users,
  ROUND(COALESCE(r.revenue, 0), 2) AS revenue,
  COALESCE(r.buyers, 0) AS buyers,
  ROUND(COALESCE(r.revenue, 0) * 1.0 / NULLIF(v.total_views, 0), 4) AS revenue_per_view,
  CASE
    WHEN v.total_views IS HIGH AND COALESCE(r.revenue, 0) IS LOW THEN 'High traffic, low monetisation'
    ELSE 'Review category performance'
  END AS diagnostic_note
FROM category_views v
LEFT JOIN category_revenue r
  ON v.category = r.category
ORDER BY revenue_per_view DESC;
