1. What is the total amount each customer spent at the restaurant?
   
<img width="171" height="68" alt="image" src="https://github.com/user-attachments/assets/119fad52-4611-4225-a416-ec3cb7b84138" />

2. How many days has each customer visited the restaurant?
<img width="209" height="71" alt="image" src="https://github.com/user-attachments/assets/1c20fc8a-9256-4421-8a2f-67a08d9183aa" />

3. What was the first item from the menu purchased by each customer?
<img width="299" height="103" alt="image" src="https://github.com/user-attachments/assets/03e786ee-3c5c-419b-bfd8-1403d70bf799" />

4. What is the most purchased item on the menu and how many times was it purchased by all customers?
<img width="213" height="37" alt="image" src="https://github.com/user-attachments/assets/45efd66d-a651-416e-bbe6-f872b5603fa0" />

5. Which item was the most popular for each customer?
<img width="313" height="106" alt="image" src="https://github.com/user-attachments/assets/2ccacaa3-5842-4f75-8914-2d99b79282ac" />

6.Which item was purchased first by the customer after they became a member?
<img width="301" height="52" alt="image" src="https://github.com/user-attachments/assets/73b1c007-9546-4d9c-9301-06e5b4aeb0b9" />

7. Which item was purchased just before the customer became a member?
<img width="373" height="67" alt="image" src="https://github.com/user-attachments/assets/16ea0483-dcd2-4802-9ea5-f8137e6fd618" />

8. What is the total items and amount spent for each member before they became a member?
<img width="266" height="51" alt="image" src="https://github.com/user-attachments/assets/705bc9ba-0732-4f8a-9a5d-e74f365c741f" />

15. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

If points are given regardless of being in the loyalty program,
```
SELECT s.customer_id, SUM(CASE WHEN m.product_name IN ('sushi') THEN price*20 ELSE price*10 END) AS points
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY points;
```
<img width="146" height="71" alt="image" src="https://github.com/user-attachments/assets/66abb6be-e9be-4b53-8aac-7bb1fc71d5ff" />

If points are given only after joining loyalty program,
```
SELECT s.customer_id, SUM(CASE WHEN m.product_name IN ('sushi') THEN price*20 ELSE price*10 END) AS points
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
JOIN members mem
ON mem.customer_id = s.customer_id
WHERE mem.join_date < s.order_date
GROUP BY s.customer_id
ORDER BY points;
```
<img width="143" height="52" alt="image" src="https://github.com/user-attachments/assets/189e1659-05f9-4a2a-a9ce-a78570397dd1" />

17. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
