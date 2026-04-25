CREATE DATABASE dannys_diner;

USE dannys_diner;

CREATE TABLE sales (
customer_id VARCHAR(5),
order_date DATE,
product_id INTEGER
);

INSERT INTO sales VALUES 
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
  
CREATE TABLE menu (
product_id INTEGER,
product_name VARCHAR(25),
price INTEGER
);

INSERT INTO menu VALUES 
('1', 'sushi', '10'),
('2', 'curry', '15'),
('3', 'ramen', '12');

CREATE TABLE members (
customer_id VARCHAR(5),
join_date DATE
);

INSERT INTO members VALUES
('A', '2021-01-07'),
('B', '2021-01-09');

-- 1. What is the total amount each customer spent at the restaurant?

SELECT customer_id, SUM(price) as total_spent
FROM sales JOIN menu ON sales.product_id = menu.product_id
GROUP BY customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date) AS no_of_days_visited
FROM sales 
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

SELECT *
FROM
(
SELECT customer_id, order_date, product_name, DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date ASC) as rn
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
) as temptable
WHERE rn = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT *
FROM
(
SELECT m.product_name, COUNT(s.order_date) as no_of_purchases
FROM menu m
JOIN sales s
ON m.product_id = s.product_id
GROUP BY product_name
) as temptable
ORDER BY no_of_purchases DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?

WITH favourites AS 
(
SELECT s.customer_id, m.product_name, count(m.product_id) as product_count,
	dense_rank() over (partition by s.customer_id order by COUNT(m.product_name) DESC) as RNK
	FROM sales s
	JOIN menu m 
	ON s.product_id = m.product_id
	GROUP BY customer_id, product_name
)

SELECT *
FROM favourites
WHERE rnk = 1;

-- 6.Which item was purchased first by the customer after they became a member?

SELECT *
FROM
(
SELECT s.customer_id, mem.join_date, m.product_name, DENSE_RANK () OVER (PARTITION BY s.customer_id ORDER BY s.order_date ASC) as rn
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
JOIN members mem
ON mem.customer_id = s.customer_id
WHERE mem.join_date <= s.order_date
) as first_purchase
WHERE rn = 1;

-- 7. Which item was purchased just before the customer became a member?

SELECT *
FROM
(
SELECT DISTINCT s.order_date, s.customer_id, mem.join_date, m.product_name, DENSE_RANK () OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) as rn
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
JOIN members mem
ON mem.customer_id = s.customer_id
WHERE mem.join_date > s.order_date	
) as purchase_before_member
WHERE rn = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id, COUNT(*) AS total_items , SUM(m.price) AS total_amt_spent
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
JOIN members mem
ON mem.customer_id = s.customer_id
WHERE mem.join_date > s.order_date	
GROUP BY customer_id
ORDER BY total_amt_spent ASC;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id, SUM(CASE WHEN m.product_name IN ('sushi') THEN price*20 ELSE price*10 END) AS points
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY points;

-- If points are given only after joining loyalty program,

SELECT s.customer_id, SUM(CASE WHEN m.product_name IN ('sushi') THEN price*20 ELSE price*10 END) AS points
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
JOIN members mem
ON mem.customer_id = s.customer_id
WHERE mem.join_date < s.order_date
GROUP BY s.customer_id
ORDER BY points;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH CTE AS (
SELECT *, join_date + INTERVAL 7 DAY AS special_end_date
FROM members 
)

SELECT s.customer_id, 
SUM(CASE WHEN s.order_date BETWEEN c.join_date AND special_end_date THEN price*20 
WHEN s.order_date NOT BETWEEN c.join_date AND special_end_date AND m.product_name IN ('sushi') THEN price*20 ELSE price*10 END) AS points
FROM CTE c
JOIN sales s
ON c.customer_id = s.customer_id
JOIN menu m
ON m.product_id = s.product_id
WHERE MONTH(s.order_date) IN ('1')
GROUP BY s.customer_id
ORDER BY points;