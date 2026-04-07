-- =====================================================
-- 05_rfm_segmentation.sql
-- Project: France E-commerce Analytics
-- Author: LI NUO
-- Objective: Build RFM segmentation for CRM strategy
-- =====================================================

-- =========================
-- 1. Base RFM Table
-- =========================
WITH reference_date AS (
    SELECT MAX(order_date) AS max_order_date
    FROM fact_orders
),

customer_metrics AS (
    SELECT
        o.user_id,
        MAX(o.order_date) AS last_order_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(o.net_revenue), 2) AS monetary,
        MAX(o.city_code) AS latest_city_code
    FROM fact_orders o
    GROUP BY o.user_id
),

rfm_base AS (
    SELECT
        cm.user_id,
        cm.latest_city_code,
        cm.last_order_date,
        DATEDIFF('day', cm.last_order_date, rd.max_order_date) AS recency_days,
        cm.frequency,
        cm.monetary
    FROM customer_metrics cm
    CROSS JOIN reference_date rd
)

-- =========================
-- 2. RFM Scoring
-- =========================
, rfm_scores AS (
    SELECT
        user_id,
        latest_city_code,
        recency_days,
        frequency,
        monetary,

        -- Recency: lower is better → reverse score
        6 - NTILE(5) OVER (ORDER BY recency_days ASC) AS r_score,

        -- Frequency & Monetary: higher is better
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score

    FROM rfm_base
)

-- =========================
-- 3. Customer Segmentation
-- =========================
, rfm_segments AS (
    SELECT
        rs.*,

        CASE
            WHEN rs.r_score >= 4 AND rs.f_score >= 4 AND rs.m_score >= 4
                THEN 'Champions'

            WHEN rs.r_score >= 3 AND rs.f_score >= 4
                THEN 'Loyal Customers'

            WHEN rs.r_score >= 4 AND rs.f_score BETWEEN 2 AND 3
                THEN 'Potential Loyalists'

            WHEN rs.r_score <= 2 AND rs.f_score >= 3
                THEN 'At Risk'

            WHEN rs.frequency = 1
                THEN 'One-time Buyers'

            ELSE 'Others'
        END AS rfm_segment

    FROM rfm_scores rs
)

-- =========================
-- 4. Segment Performance
-- =========================
, segment_stats AS (
    SELECT
        rfm_segment,
        COUNT(*) AS customers,
        ROUND(SUM(monetary), 2) AS revenue,
        ROUND(AVG(monetary), 2) AS avg_customer_value
    FROM rfm_segments
    GROUP BY rfm_segment
),

total_revenue AS (
    SELECT SUM(revenue) AS total_rev
    FROM segment_stats
)

SELECT
    s.rfm_segment,
    s.customers,
    s.revenue,
    s.avg_customer_value,
    ROUND(s.revenue * 1.0 / NULLIF(t.total_rev, 0), 4) AS revenue_share
FROM segment_stats s
CROSS JOIN total_revenue t
ORDER BY s.revenue DESC;

-- =========================
-- 5. Segment by City
-- =========================
SELECT
    c.city_name,
    r.rfm_segment,
    COUNT(*) AS customers,
    ROUND(SUM(r.monetary), 2) AS revenue
FROM rfm_segments r
LEFT JOIN dim_city_fr c
    ON r.latest_city_code = c.city_code
GROUP BY c.city_name, r.rfm_segment
ORDER BY c.city_name, revenue DESC;

-- =========================
-- 6. CRM Actions
-- =========================
SELECT
    rfm_segment,

    CASE
        WHEN rfm_segment = 'Champions'
            THEN 'VIP strategy: exclusives, early access, premium experience'

        WHEN rfm_segment = 'Loyal Customers'
            THEN 'Increase basket size via cross-sell and bundles'

        WHEN rfm_segment = 'Potential Loyalists'
            THEN 'Drive second purchase with targeted incentives'

        WHEN rfm_segment = 'At Risk'
            THEN 'Win-back campaigns and churn prevention'

        WHEN rfm_segment = 'One-time Buyers'
            THEN 'Convert to repeat customers via lifecycle marketing'

        ELSE 'Standard CRM nurturing'
    END AS recommended_action,

    COUNT(*) AS customers,
    ROUND(SUM(monetary), 2) AS revenue

FROM rfm_segments
GROUP BY rfm_segment
ORDER BY revenue DESC;
