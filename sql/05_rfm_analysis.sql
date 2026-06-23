DROP TABLE IF EXISTS rfm_score;

CREATE TABLE rfm_score AS
WITH user_rfm_raw AS (
    SELECT
        customer_unique_id,
        DATEDIFF('2018-10-01', MAX(purchase_time)) AS recency_days,
        COUNT(DISTINCT order_id) AS frequency,
        SUM(payment_value) AS monetary
    FROM order_wide
    WHERE order_status = 'delivered'
      AND purchase_time IS NOT NULL
    GROUP BY customer_unique_id
)
SELECT
    customer_unique_id,
    recency_days,
    frequency,
    monetary,
    -- R 评分：基于最近消费天数（越小越好）
    CASE
        WHEN recency_days <= 30  THEN 5
        WHEN recency_days <= 60  THEN 4
        WHEN recency_days <= 90  THEN 3
        WHEN recency_days <= 180 THEN 2
        ELSE 1
    END AS r_score,
    -- F 评分：基于消费频率（越大越好）
    CASE
        WHEN frequency >= 5 THEN 5
        WHEN frequency >= 3 THEN 4
        WHEN frequency >= 2 THEN 3
        WHEN frequency >= 1 THEN 2
        ELSE 1
    END AS f_score,
    -- M 评分：基于消费金额（越大越好）
    CASE
        WHEN monetary >= 1000 THEN 5
        WHEN monetary >= 500  THEN 4
        WHEN monetary >= 200  THEN 3
        WHEN monetary >= 100  THEN 2
        ELSE 1
    END AS m_score
FROM user_rfm_raw;

-- 1. 分数分布（应该有明显倾斜，不再是均分）
SELECT r_score, COUNT(*) AS cnt FROM rfm_score GROUP BY r_score ORDER BY r_score DESC;
SELECT f_score, COUNT(*) AS cnt FROM rfm_score GROUP BY f_score ORDER BY f_score DESC;
SELECT m_score, COUNT(*) AS cnt FROM rfm_score GROUP BY m_score ORDER BY m_score DESC;

-- 2. 检查高频用户是否在高分段
SELECT * FROM rfm_score WHERE frequency >= 3 ORDER BY frequency DESC LIMIT 10;