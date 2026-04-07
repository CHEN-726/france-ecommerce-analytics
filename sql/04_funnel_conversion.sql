-- 04_funnel_conversion.sql
-- France e-commerce analytics project
-- Objective: diagnose funnel leakage and compare conversion performance across dimensions

-- 1. Overall funnel (distinct users by stage)
SELECT
  event_type,
  COUNT(DISTINCT user_id) AS users_at_stage
FROM fact_events
WHERE event_type IN ('view', 'favorite', 'add_to_cart', 'purchase')
GROUP BY event_type
ORDER BY
  CASE
    WHEN event_type = 'view' THEN 1
    WHEN event_type = 'favorite' THEN 2
    WHEN event_type = 'add_to_cart' THEN 3
    WHEN event_type = 'purchase' THEN 4
  END;

-- 2. Overall funnel conversion rates
WITH funnel AS (
  SELECT
    COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) AS view_users,
    COUNT(DISTINCT CASE WHEN event_type = 'favorite' THEN user_id END) AS favorite_users,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS cart_users,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchase_users
  FROM fact_events
)
SELECT
  view_users,
  favorite_users,
  cart_users,
  purchase_users,
  ROUND(favorite_users * 1.0 / NULLIF(view_users, 0), 4) AS view_to_favorite_rate,
  ROUND(cart_users * 1.0 / NULLIF(view_users, 0), 4) AS view_to_cart_rate,
  ROUND(purchase_users * 1.0 / NULLIF(view_users, 0), 4) AS view_to_purchase_rate,
  ROUND(purchase_users * 1.0 / NULLIF(cart_users, 0), 4) AS cart_to_purchase_rate
FROM funnel;

-- 3. Monthly funnel
SELECT
  DATE_TRUNC('month', event_date) AS event_month,
  COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) AS view_users,
  COUNT(DISTINCT CASE WHEN event_type = 'favorite' THEN user_id END) AS favorite_users,
  COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS cart_users,
  COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchase_users,
  ROUND(
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) * 1.0
    / NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END), 0),
    4
  ) AS view_to_purchase_rate
FROM fact_events
GROUP BY 1
ORDER BY 1;

-- 4. Funnel by city
SELECT
  c.city_name,
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
LEFT JOIN dim_city_fr c
  ON e.city_code = c.city_code
GROUP BY c.city_name
ORDER BY purchase_users DESC;

-- 5. Funnel by channel
SELECT
  channel,
  COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) AS view_users,
  COUNT(DISTINCT CASE WHEN event_type = 'favorite' THEN user_id END) AS favorite_users,
  COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS cart_users,
  COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchase_users,
  ROUND(
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) * 1.0
    / NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END), 0),
    4
  ) AS view_to_purchase_rate,
  ROUND(
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) * 1.0
    / NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END), 0),
    4
  ) AS cart_to_purchase_rate
FROM fact_events
GROUP BY channel
ORDER BY purchase_users DESC;

-- 6. Funnel by device
SELECT
  device_type,
  COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) AS view_users,
  COUNT(DISTINCT CASE WHEN event_type = 'favorite' THEN user_id END) AS favorite_users,
  COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS cart_users,
  COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchase_users,
  ROUND(
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) * 1.0
    / NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END), 0),
    4
  ) AS view_to_purchase_rate,
  ROUND(
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) * 1.0
    / NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END), 0),
    4
  ) AS cart_to_purchase_rate
FROM fact_events
GROUP BY device_type
ORDER BY purchase_users DESC;

-- 7. New vs returning funnel
SELECT
  new_vs_returning,
  COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) AS view_users,
  COUNT(DISTINCT CASE WHEN event_type = 'favorite' THEN user_id END) AS favorite_users,
  COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS cart_users,
  COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchase_users,
  ROUND(
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) * 1.0
    / NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END), 0),
    4
  ) AS view_to_purchase_rate
FROM fact_events
GROUP BY new_vs_returning
ORDER BY purchase_users DESC;

-- 8. Favorite to purchase conversion
WITH favorite_users AS (
  SELECT DISTINCT user_id
  FROM fact_events
  WHERE event_type = 'favorite'
),
purchase_users AS (
  SELECT DISTINCT user_id
  FROM fact_events
  WHERE event_type = 'purchase'
)
SELECT
  COUNT(*) AS favorite_users,
  COUNT(CASE WHEN p.user_id IS NOT NULL THEN 1 END) AS favorite_users_who_purchased,
  ROUND(
    COUNT(CASE WHEN p.user_id IS NOT NULL THEN 1 END) * 1.0 / NULLIF(COUNT(*), 0),
    4
  ) AS favorite_to_purchase_rate
FROM favorite_users f
LEFT JOIN purchase_users p
  ON f.user_id = p.user_id;

-- 9. Cart to purchase conversion
WITH cart_users AS (
  SELECT DISTINCT user_id
  FROM fact_events
  WHERE event_type = 'add_to_cart'
),
purchase_users AS (
  SELECT DISTINCT user_id
  FROM fact_events
  WHERE event_type = 'purchase'
)
SELECT
  COUNT(*) AS cart_users,
  COUNT(CASE WHEN p.user_id IS NOT NULL THEN 1 END) AS cart_users_who_purchased,
  ROUND(
    COUNT(CASE WHEN p.user_id IS NOT NULL THEN 1 END) * 1.0 / NULLIF(COUNT(*), 0),
    4
  ) AS cart_to_purchase_rate
FROM cart_users c
LEFT JOIN purchase_users p
  ON c.user_id = p.user_id;

-- 10. City × channel funnel diagnosis
SELECT
  c.city_name,
  e.channel,
  COUNT(DISTINCT CASE WHEN e.event_type = 'view' THEN e.user_id END) AS view_users,
  COUNT(DISTINCT CASE WHEN e.event_type = 'purchase' THEN e.user_id END) AS purchase_users,
  ROUND(
    COUNT(DISTINCT CASE WHEN e.event_type = 'purchase' THEN e.user_id END) * 1.0
    / NULLIF(COUNT(DISTINCT CASE WHEN e.event_type = 'view' THEN e.user_id END), 0),
    4
  ) AS view_to_purchase_rate
FROM fact_events e
LEFT JOIN dim_city_fr c
  ON e.city_code = c.city_code
GROUP BY c.city_name, e.channel
ORDER BY c.city_name, view_to_purchase_rate DESC;
