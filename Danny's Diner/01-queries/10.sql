WITH dates_cte AS (
  SELECT 
    customer_id, 
      join_date, 
      join_date + 6 AS valid_date, 
      DATE_TRUNC(
        'month', '2021-01-31'::DATE)
        + interval '1 month' 
        - interval '1 day' AS last_date
  FROM dannys_diner.members
)

SELECT 
  sales.customer_id, 
  SUM(CASE
    WHEN menu.product_name = 'sushi' THEN 2 * 10 * menu.price
    WHEN sales.order_date BETWEEN dates.join_date AND dates.valid_date THEN 2 * 10 * menu.price
    ELSE 10 * menu.price END) AS points
FROM dannys_diner.sales
INNER JOIN dates_cte AS dates
  ON sales.customer_id = dates.customer_id
  AND dates.join_date <= sales.order_date
  AND sales.order_date <= dates.last_date
INNER JOIN dannys_diner.menu
  ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY points DESC;