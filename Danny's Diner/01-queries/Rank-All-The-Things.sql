WITH customers_data AS (
  SELECT 
    sales.customer_id, 
    sales.order_date,  
    menu.product_name, 
    menu.price,
    CASE
      WHEN members.join_date > sales.order_date THEN 'N'
      WHEN members.join_date <= sales.order_date THEN 'Y'
      ELSE 'N' END AS member_status
  FROM dannys_diner.sales
  LEFT JOIN dannys_diner.members
    ON sales.customer_id = members.customer_id
  INNER JOIN dannys_diner.menu
    ON sales.product_id = menu.product_id
)

SELECT 
  *, 
  CASE
    WHEN member_status = 'N' then NULL
    ELSE RANK () OVER (
      PARTITION BY customer_id, member_status
      ORDER BY order_date
  ) END AS ranking
FROM customers_data;