DROP TABLE IF EXISTS kpi_summary;

CREATE TABLE kpi_summary AS
SELECT
    DATE_FORMAT(purchase_time, '%Y-%m') AS month,
    COUNT(DISTINCT order_id)             AS total_orders,
    COUNT(DISTINCT customer_unique_id)   AS total_users,          -- 改为唯一用户ID
    SUM(payment_value)                   AS gmv,
    ROUND(SUM(payment_value) / COUNT(DISTINCT order_id), 2) AS avg_order_value,
    ROUND(SUM(payment_value) / COUNT(DISTINCT customer_unique_id), 2) AS avg_user_spend
FROM order_wide
WHERE order_status = 'delivered'
  AND purchase_time IS NOT NULL
GROUP BY DATE_FORMAT(purchase_time, '%Y-%m')
ORDER BY month;

-- 验证
SELECT
    SUM(total_orders)    AS all_orders,
    SUM(total_users)     AS all_users,
    SUM(gmv)             AS total_gmv,
    ROUND(SUM(gmv) / SUM(total_orders), 2) AS overall_avg_order,
    ROUND(SUM(gmv) / SUM(total_users), 2)  AS overall_avg_user
FROM kpi_summary;