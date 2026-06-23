DROP TABLE IF EXISTS order_wide;

CREATE TABLE order_wide AS
SELECT
    o.order_id,
    o.customer_id,                      -- 保留订单级ID，仅备查
    c.customer_unique_id,               -- 业务唯一用户ID，后续分析以此为准
    o.order_purchase_timestamp AS purchase_time,
    COALESCE(pymt.total_payment, 0) AS payment_value,
    o.order_status,
    oi.product_count
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id   -- 关键修正：关联唯一用户ID
LEFT JOIN (
    SELECT order_id, SUM(payment_value) AS total_payment
    FROM order_payments
    GROUP BY order_id
) pymt ON o.order_id = pymt.order_id
LEFT JOIN (
    SELECT order_id, COUNT(DISTINCT product_id) AS product_count
    FROM order_items
    GROUP BY order_id
) oi ON o.order_id = oi.order_id;
