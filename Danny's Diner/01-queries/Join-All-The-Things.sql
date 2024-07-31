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
ORDER BY members.customer_id, sales.order_date;