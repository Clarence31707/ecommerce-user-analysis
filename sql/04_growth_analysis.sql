DROP TABLE IF EXISTS monthly_growth;

CREATE TABLE monthly_growth AS
WITH
-- 1. 用户首次购买月份
first_purchase AS (
    SELECT
        customer_unique_id,
        DATE_FORMAT(MIN(purchase_time), '%Y-%m') AS first_month
    FROM order_wide
    WHERE order_status = 'delivered'
      AND purchase_time IS NOT NULL
    GROUP BY customer_unique_id
),

-- 2. 用户累计订单数（截至每月）
user_monthly_orders AS (
    SELECT
        customer_unique_id,
        DATE_FORMAT(purchase_time, '%Y-%m') AS month,
        COUNT(DISTINCT order_id) AS orders_in_month
    FROM order_wide
    WHERE order_status = 'delivered'
      AND purchase_time IS NOT NULL
    GROUP BY customer_unique_id, month
),

-- 3. 每月活跃用户（MAU）与复购标记
monthly_active AS (
    SELECT
        umo.month,
        umo.customer_unique_id,
        -- 判断该用户到本月为止的累计订单数
        (
            SELECT SUM(orders_in_month)
            FROM user_monthly_orders umo2
            WHERE umo2.customer_unique_id = umo.customer_unique_id
              AND umo2.month <= umo.month
        ) AS cumulative_orders
    FROM user_monthly_orders umo
)

SELECT
    ma.month,
    -- 新增用户：首次购买月份 = 当前月
    COUNT(DISTINCT CASE WHEN fp.first_month = ma.month THEN ma.customer_unique_id END) AS new_users,
    -- MAU
    COUNT(DISTINCT ma.customer_unique_id) AS mau,
    -- 复购用户：累计订单数 >= 2
    COUNT(DISTINCT CASE WHEN ma.cumulative_orders >= 2 THEN ma.customer_unique_id END) AS repeat_users,
    -- 复购率
    ROUND(
        COUNT(DISTINCT CASE WHEN ma.cumulative_orders >= 2 THEN ma.customer_unique_id END) * 100.0
        / COUNT(DISTINCT ma.customer_unique_id), 2
    ) AS repeat_rate
FROM monthly_active ma
LEFT JOIN first_purchase fp ON ma.customer_unique_id = fp.customer_unique_id
GROUP BY ma.month
ORDER BY ma.month;

-- 查看月度明细
SELECT * FROM monthly_growth;

-- 整体汇总（观察复购率总体水平）
SELECT
    SUM(new_users)    AS total_new_users,
    SUM(mau)          AS total_mau_events,
    SUM(repeat_users) AS total_repeat_events
FROM monthly_growth;

-- 检查 first_purchase 是否覆盖了全部用户
SELECT COUNT(DISTINCT customer_unique_id)
FROM order_wide
WHERE order_status = 'delivered' AND purchase_time IS NOT NULL;