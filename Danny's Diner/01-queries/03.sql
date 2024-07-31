WITH ordered_sales AS (
  SELECT 
    sales.customer_id, 
    sales.order_date, 
    menu.product_name,
    DENSE_RANK() OVER (
      PARTITION BY sales.customer_id 
      ORDER BY sales.order_date) AS rank
  FROM dannys_diner.sales
  INNER JOIN dannys_diner.menu
    ON sales.product_id = menu.product_id
)

SELECT 
  customer_id, 
  product_name
FROM ordered_sales
WHERE rank = 1
GROUP BY customer_id, product_name;