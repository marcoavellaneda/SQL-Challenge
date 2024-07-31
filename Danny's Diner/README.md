## Danny's Dinner

<img src= "https://8weeksqlchallenge.com/images/case-study-designs/1.png" height=475px width=450px>

### Introdução
Danny adora comida japonesa, então no início de 2021, ele decide embarcar em uma aventura arriscada e abre um pequeno e charmoso restaurante que vende suas três comidas favoritas: sushi, curry e ramen.

O Danny’s Diner precisa da sua ajuda para manter o restaurante funcionando - eles capturaram alguns dados básicos durante os poucos meses de operação, mas não sabem como usá-los para gerenciar o negócio.

### Declaração do Problema
Danny quer usar os dados para responder a algumas perguntas simples sobre seus clientes, especialmente sobre seus padrões de visita, quanto dinheiro eles gastaram e também quais itens do menu são os favoritos. Ter essa conexão mais profunda com seus clientes o ajudará a oferecer uma experiência melhor e mais personalizada para seus clientes fiéis.

Ele planeja usar esses insights para decidir se deve expandir o programa de fidelidade existente - além disso, ele precisa de ajuda para gerar alguns conjuntos de dados básicos para que sua equipe possa inspecionar facilmente os dados sem precisar usar SQL.

Danny forneceu uma amostra dos dados gerais de seus clientes devido a questões de privacidade - mas ele espera que esses exemplos sejam suficientes para que você escreva consultas SQL totalmente funcionais para ajudá-lo a responder suas perguntas!

---

## Diagrama de Relacionamento entre Entidades

![!\[alt text\](image-1.png)](https://user-images.githubusercontent.com/81607668/127271130-dca9aedd-4ca9-4ed8-b6ec-1e1920dca4a8.png)


---

### Perguntas de estudo de caso

#### Qual o total gasto por cada cliente no restaurante ?

````sql
SELECT 
  sales.customer_id, 
  SUM(menu.price) AS total_sales
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu
  ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id ASC; 
````



| customer_id | total_sales |
| ----------- | ----------- |
| A           | 76          |
| B           | 74          |
| C           | 36          |

- Cliente A gastou $76;
- Cliente B gastou $74;
- Cliente C gastou $36.

---

#### Quantos dias cada cliente visitou o restaurante ?
````sql
SELECT 
  customer_id, 
  COUNT(DISTINCT order_date) AS visit_count
FROM dannys_diner.sales
GROUP BY customer_id;
````

##### Solução:

| customer_id | visit_count |
| ----------- | ----------- |
| A           | 4          |
| B           | 6          |
| C           | 2          |

- Cliente A visitou 4 vezes;
- Cliente B visitou 6 vezes;
- Cliente C visitou 2 vezes.

***


#### Qual foi o primeiro item do cardápio adquirido por cada cliente?

````sql
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
````


| customer_id | product_name | 
| ----------- | ----------- |
| A           | curry        | 
| A           | sushi        | 
| B           | curry        | 
| C           | ramen        |

O Cliente A fez um pedido de curry e sushi simultaneamente, tornando-os os primeiros itens do pedido;
O primeiro pedido do Cliente B foi curry;
O primeiro pedido do Cliente C foi ramen.


***

#### Qual é o item mais vendido do cardápio e quantas vezes foi comprado por todos os clientes?

````sql
SELECT 
  menu.product_name,
  COUNT(sales.product_id) AS most_purchased_item
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu
  ON sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY most_purchased_item DESC
LIMIT 1;
````



| most_purchased | product_name | 
| ----------- | ----------- |
| 8       | ramen |


- O item mais pedido do cardápio foi o ``ramen``, com 8 pedidos no total.

***

#### Qual foi o item favorito de cada cliente?

````sql
WITH most_popular AS (
  SELECT 
    sales.customer_id, 
    menu.product_name, 
    COUNT(menu.product_id) AS order_count,
    DENSE_RANK() OVER (
      PARTITION BY sales.customer_id 
      ORDER BY COUNT(sales.customer_id) DESC) AS rank
  FROM dannys_diner.menu
  INNER JOIN dannys_diner.sales
    ON menu.product_id = sales.product_id
  GROUP BY sales.customer_id, menu.product_name
)

SELECT 
  customer_id, 
  product_name, 
  order_count
FROM most_popular 
WHERE rank = 1;
````




| customer_id | product_name | order_count |
| ----------- | ---------- |------------  |
| A           | ramen        |  3   |
| B           | sushi        |  2   |
| B           | curry        |  2   |
| B           | ramen        |  2   |
| C           | ramen        |  3   |

O item favorito dos Clientes A e C foi o ``ramen``;
O Cliente B realizou a mesma quantidade de pedidos para todos os 3 itens do cardápio.

***

#### Qual item foi comprado primeiro pelo cliente logo depois que ele se tornou membro?

```sql
WITH joined_as_member AS (
  SELECT
    members.customer_id, 
    sales.product_id,
    ROW_NUMBER() OVER (
      PARTITION BY members.customer_id
      ORDER BY sales.order_date) AS row_num
  FROM dannys_diner.members
  INNER JOIN dannys_diner.sales
    ON members.customer_id = sales.customer_id
    AND sales.order_date > members.join_date
)

SELECT 
  customer_id, 
  product_name 
FROM joined_as_member
INNER JOIN dannys_diner.menu
  ON joined_as_member.product_id = menu.product_id
WHERE row_num = 1
ORDER BY customer_id ASC;
```


| customer_id | product_name |
| ----------- | ---------- |
| A           | ramen        |
| B           | sushi        |

O primeiro pedido do Cliente A como membro foi o ``ramen``;
O primeiro pedido do Cliente B como membro foi o ``sushi``.

***

#### Qual foi o último item comprado antes do cliente se tornar membro?

````sql
WITH purchased_prior_member AS (
  SELECT 
    members.customer_id, 
    sales.product_id,
    ROW_NUMBER() OVER (
      PARTITION BY members.customer_id
      ORDER BY sales.order_date DESC) AS rank
  FROM dannys_diner.members
  INNER JOIN dannys_diner.sales
    ON members.customer_id = sales.customer_id
    AND sales.order_date < members.join_date
)

SELECT 
  p_member.customer_id, 
  menu.product_name 
FROM purchased_prior_member AS p_member
INNER JOIN dannys_diner.menu
  ON p_member.product_id = menu.product_id
WHERE rank = 1
ORDER BY p_member.customer_id ASC;
````


| customer_id | product_name |
| ----------- | ---------- |
| A           | sushi        |
| B           | sushi        |

O último pedido de ambos os clientes antes de se tornarem membros foi sushi.

***

####  Qual é o total de itens e o valor gasto para cada membro antes de se tornarem membros?

```sql
SELECT 
  sales.customer_id, 
  COUNT(sales.product_id) AS total_items, 
  SUM(menu.price) AS total_sales
FROM dannys_diner.sales
INNER JOIN dannys_diner.members
  ON sales.customer_id = members.customer_id
  AND sales.order_date < members.join_date
INNER JOIN dannys_diner.menu
  ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id;
```

##### Solução:

| customer_id | total_items | total_sales |
| ----------- | ----------  |----------   |
| A           | 2           |  25         |
| B           | 3           |  40         |

Antes de se tornarem membros:
- Cliente A gastou $25 em 2 itens.
- Cliente B gastou $40 em 3 itens.

***

####  Se cada $ 1 gasto equivale a 10 pontos e o sushi tem um multiplicador de 2x pontos - quantos pontos cada cliente teria?

```sql
WITH points_cte AS (
  SELECT 
    menu.product_id, 
    CASE
      WHEN product_id = 1 THEN price * 20
      ELSE price * 10 END AS points
  FROM dannys_diner.menu
)

SELECT 
  sales.customer_id, 
  SUM(points_cte.points) AS total_points
FROM dannys_diner.sales
INNER JOIN points_cte
  ON sales.product_id = points_cte.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id;
```


| customer_id | total_points | 
| ----------- | ---------- |
| A           | 860 |
| B           | 940 |
| C           | 360 |

- Total de pontos do Cliente A => 860;
- Total de pontos do Cliente B => 940;
- Total de pontos do Cliente C => 360.

***

####  Na primeira semana após um cliente aderir ao programa (incluindo a data de adesão), ele ganha 2x pontos em todos os itens, não apenas em sushi - quantos pontos os clientes A e B têm no final de janeiro?

```sql
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
```



| customer_id | total_points | 
| ----------- | ---------- |
| A           | 1020 |
| B           | 320 |

- Total de pontos do Cliente A => 1.020;
- Total de pontos do Cliente B => 320.

***

## Questões Bônus
#### Join All The Things

Recrie a tabela com: customer_id, order_date, product_name, price, member (Y/N)

```sql
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
ORDER BY members.customer_id, sales.order_date
```
 
| customer_id | order_date | product_name | price | member |
| ----------- | ---------- | -------------| ----- | ------ |
| A           | 2021-01-01 | sushi        | 10    | N      |
| A           | 2021-01-01 | curry        | 15    | N      |
| A           | 2021-01-07 | curry        | 15    | Y      |
| A           | 2021-01-10 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| B           | 2021-01-01 | curry        | 15    | N      |
| B           | 2021-01-02 | curry        | 15    | N      |
| B           | 2021-01-04 | sushi        | 10    | N      |
| B           | 2021-01-11 | sushi        | 10    | Y      |
| B           | 2021-01-16 | ramen        | 12    | Y      |
| B           | 2021-02-01 | ramen        | 12    | Y      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-07 | ramen        | 12    | N      |

***

#### Rank All The Things

Danny também precisa de mais informações sobre o ``ranking`` dos produtos dos clientes, mas ele propositalmente não precisa do ranking para compras de não-membros, então ele espera valores de ranking nulos para os registros quando os clientes ainda não fazem parte do programa de fidelidade.

```sql
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
```

| customer_id | order_date | product_name | price | member | ranking | 
| ----------- | ---------- | -------------| ----- | ------ |-------- |
| A           | 2021-01-01 | sushi        | 10    | N      | NULL
| A           | 2021-01-01 | curry        | 15    | N      | NULL
| A           | 2021-01-07 | curry        | 15    | Y      | 1
| A           | 2021-01-10 | ramen        | 12    | Y      | 2
| A           | 2021-01-11 | ramen        | 12    | Y      | 3
| A           | 2021-01-11 | ramen        | 12    | Y      | 3
| B           | 2021-01-01 | curry        | 15    | N      | NULL
| B           | 2021-01-02 | curry        | 15    | N      | NULL
| B           | 2021-01-04 | sushi        | 10    | N      | NULL
| B           | 2021-01-11 | sushi        | 10    | Y      | 1
| B           | 2021-01-16 | ramen        | 12    | Y      | 2
| B           | 2021-02-01 | ramen        | 12    | Y      | 3
| C           | 2021-01-01 | ramen        | 12    | N      | NULL
| C           | 2021-01-01 | ramen        | 12    | N      | NULL
| C           | 2021-01-07 | ramen        | 12    | N      | NULL

***
