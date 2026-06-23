DROP TABLE IF EXISTS user_segment;

CREATE TABLE user_segment AS
SELECT
    customer_unique_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
            THEN '高价值用户'
        WHEN r_score >= 4 AND f_score <= 2 AND m_score = 3
            THEN '潜力用户'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2
            THEN '沉睡用户'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score = 3
            THEN '流失风险用户'
        ELSE '其他'
    END AS segment
FROM rfm_score;

-- 各分层人数及占比
SELECT
    segment,
    COUNT(*) AS user_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM user_segment
GROUP BY segment
ORDER BY user_count DESC;

-- 抽查高价值用户
SELECT * FROM user_segment WHERE segment = '高价值用户' LIMIT 5;