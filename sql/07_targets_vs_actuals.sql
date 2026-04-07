-- 07_targets_vs_actuals.sql
-- France e-commerce analytics project
-- Objective: compare actual performance against monthly targets and identify over/underperformance

-- 1. Actual revenue by month × city × category
SELECT
  DATE_TRUNC('month', o.order_date) AS target_month,
  o.city_code,
  p.category,
  ROUND(SUM(o.net_revenue), 2) AS actual_revenue,
  COUNT(DISTINCT o.order_id) AS actual_orders,
  COUNT(DISTINCT o.user_id) AS actual_buyers
FROM fact_orders o
LEFT JOIN dim_products p
  ON o.product_id = p.product_id
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

-- 2. Full target vs actual table
WITH actuals AS (
  SELECT
    DATE_TRUNC('month', o.order_date) AS target_month,
    o.city_code,
    p.category,
    SUM(o.net_revenue) AS actual_revenue,
    COUNT(DISTINCT o.order_id) AS actual_orders,
    COUNT(DISTINCT o.user_id) AS actual_buyers
  FROM fact_orders o
  LEFT JOIN dim_products p
    ON o.product_id = p.product_id
  GROUP BY 1, 2, 3
)
SELECT
  t.target_month,
  c.city_name,
  t.city_code,
  t.category,
  ROUND(t.target_revenue, 2) AS target_revenue,
  ROUND(COALESCE(a.actual_revenue, 0), 2) AS actual_revenue,
  ROUND(COALESCE(a.actual_revenue, 0) - t.target_revenue, 2) AS revenue_gap,
  ROUND(COALESCE(a.actual_revenue, 0) * 1.0 / NULLIF(t.target_revenue, 0), 4) AS target_attainment,
  t.target_orders,
  COALESCE(a.actual_orders, 0) AS actual_orders,
  COALESCE(a.actual_orders, 0) - t.target_orders AS order_gap,
  t.target_buyers,
  COALESCE(a.actual_buyers, 0) AS actual_buyers,
  COALESCE(a.actual_buyers, 0) - t.target_buyers AS buyer_gap,
  t.priority_focus_flag
FROM dim_targets_monthly t
LEFT JOIN actuals a
  ON t.target_month = a.target_month
 AND t.city_code = a.city_code
 AND t.category = a.category
LEFT JOIN dim_city_fr c
  ON t.city_code = c.city_code
ORDER BY t.target_month, c.city_name, t.category;

-- 3. Monthly total target vs actual
WITH monthly_actuals AS (
  SELECT
    DATE_TRUNC('month', o.order_date) AS target_month,
    SUM(o.net_revenue) AS actual_revenue
  FROM fact_orders o
  GROUP BY 1
),
monthly_targets AS (
  SELECT
    target_month,
    SUM(target_revenue) AS target_revenue
  FROM dim_targets_monthly
  GROUP BY 1
)
SELECT
  mt.target_month,
  ROUND(mt.target_revenue, 2) AS target_revenue,
  ROUND(COALESCE(ma.actual_revenue, 0), 2) AS actual_revenue,
  ROUND(COALESCE(ma.actual_revenue, 0) - mt.target_revenue, 2) AS revenue_gap,
  ROUND(COALESCE(ma.actual_revenue, 0) * 1.0 / NULLIF(mt.target_revenue, 0), 4) AS target_attainment
FROM monthly_targets mt
LEFT JOIN monthly_actuals ma
  ON mt.target_month = ma.target_month
ORDER BY mt.target_month;

-- 4. City-level target attainment by month
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
  ROUND(ct.target_revenue, 2) AS target_revenue,
  ROUND(COALESCE(ca.actual_revenue, 0), 2) AS actual_revenue,
  ROUND(COALESCE(ca.actual_revenue, 0) - ct.target_revenue, 2) AS revenue_gap,
  ROUND(COALESCE(ca.actual_revenue, 0) * 1.0 / NULLIF(ct.target_revenue, 0), 4) AS target_attainment
FROM city_targets ct
LEFT JOIN city_actuals ca
  ON ct.target_month = ca.target_month
 AND ct.city_code = ca.city_code
LEFT JOIN dim_city_fr c
  ON ct.city_code = c.city_code
ORDER BY ct.target_month, target_attainment DESC;

-- 5. Category-level target attainment by month
WITH category_actuals AS (
  SELECT
    DATE_TRUNC('month', o.order_date) AS target_month,
    p.category,
    SUM(o.net_revenue) AS actual_revenue
  FROM fact_orders o
  LEFT JOIN dim_products p
    ON o.product_id = p.product_id
  GROUP BY 1, 2
),
category_targets AS (
  SELECT
    target_month,
    category,
    SUM(target_revenue) AS target_revenue
  FROM dim_targets_monthly
  GROUP BY 1, 2
)
SELECT
  ct.target_month,
  ct.category,
  ROUND(ct.target_revenue, 2) AS target_revenue,
  ROUND(COALESCE(ca.actual_revenue, 0), 2) AS actual_revenue,
  ROUND(COALESCE(ca.actual_revenue, 0) - ct.target_revenue, 2) AS revenue_gap,
  ROUND(COALESCE(ca.actual_revenue, 0) * 1.0 / NULLIF(ct.target_revenue, 0), 4) AS target_attainment
FROM category_targets ct
LEFT JOIN category_actuals ca
  ON ct.target_month = ca.target_month
 AND ct.category = ca.category
ORDER BY ct.target_month, target_attainment DESC;

-- 6. Best and worst performing city-category combinations
WITH target_actual AS (
  SELECT
    t.target_month,
    t.city_code,
    t.category,
    t.target_revenue,
    COALESCE(a.actual_revenue, 0) AS actual_revenue,
    COALESCE(a.actual_revenue, 0) - t.target_revenue AS revenue_gap,
    COALESCE(a.actual_revenue, 0) * 1.0 / NULLIF(t.target_revenue, 0) AS target_attainment
  FROM dim_targets_monthly t
  LEFT JOIN (
    SELECT
      DATE_TRUNC('month', o.order_date) AS target_month,
      o.city_code,
      p.category,
      SUM(o.net_revenue) AS actual_revenue
    FROM fact_orders o
    LEFT JOIN dim_products p
      ON o.product_id = p.product_id
    GROUP BY 1, 2, 3
  ) a
    ON t.target_month = a.target_month
   AND t.city_code = a.city_code
   AND t.category = a.category
)
SELECT
  c.city_name,
  ta.category,
  ta.target_month,
  ROUND(ta.target_revenue, 2) AS target_revenue,
  ROUND(ta.actual_revenue, 2) AS actual_revenue,
  ROUND(ta.revenue_gap, 2) AS revenue_gap,
  ROUND(ta.target_attainment, 4) AS target_attainment
FROM target_actual ta
LEFT JOIN dim_city_fr c
  ON ta.city_code = c.city_code
ORDER BY ta.target_attainment DESC, ta.revenue_gap DESC;

-- 7. Performance label for management diagnosis
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
),
city_comparison AS (
  SELECT
    ct.target_month,
    ct.city_code,
    ct.target_revenue,
    COALESCE(ca.actual_revenue, 0) AS actual_revenue,
    COALESCE(ca.actual_revenue, 0) - ct.target_revenue AS revenue_gap,
    COALESCE(ca.actual_revenue, 0) * 1.0 / NULLIF(ct.target_revenue, 0) AS target_attainment
  FROM city_targets ct
  LEFT JOIN city_actuals ca
    ON ct.target_month = ca.target_month
   AND ct.city_code = ca.city_code
)
SELECT
  c.city_name,
  cc.target_month,
  ROUND(cc.target_revenue, 2) AS target_revenue,
  ROUND(cc.actual_revenue, 2) AS actual_revenue,
  ROUND(cc.revenue_gap, 2) AS revenue_gap,
  ROUND(cc.target_attainment, 4) AS target_attainment,
  CASE
    WHEN cc.target_attainment >= 1.05 THEN 'Over target'
    WHEN cc.target_attainment >= 0.95 THEN 'Near target'
    ELSE 'Under target'
  END AS performance_label
FROM city_comparison cc
LEFT JOIN dim_city_fr c
  ON cc.city_code = c.city_code
ORDER BY cc.target_month, cc.target_attainment DESC;

-- 8. Priority market focus tracking
WITH target_actual AS (
  SELECT
    t.target_month,
    t.city_code,
    t.category,
    t.priority_focus_flag,
    t.target_revenue,
    COALESCE(a.actual_revenue, 0) AS actual_revenue,
    COALESCE(a.actual_revenue, 0) * 1.0 / NULLIF(t.target_revenue, 0) AS target_attainment
  FROM dim_targets_monthly t
  LEFT JOIN (
    SELECT
      DATE_TRUNC('month', o.order_date) AS target_month,
      o.city_code,
      p.category,
      SUM(o.net_revenue) AS actual_revenue
    FROM fact_orders o
    LEFT JOIN dim_products p
      ON o.product_id = p.product_id
    GROUP BY 1, 2, 3
  ) a
    ON t.target_month = a.target_month
   AND t.city_code = a.city_code
   AND t.category = a.category
)
SELECT
  target_month,
  priority_focus_flag,
  COUNT(*) AS rows_count,
  ROUND(AVG(target_attainment), 4) AS avg_target_attainment
FROM target_actual
GROUP BY target_month, priority_focus_flag
ORDER BY target_month, priority_focus_flag;
