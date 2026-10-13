1. What was the total quantity sold for all products?

```
SELECT d.product_name, SUM(s.qty) AS total_qty
FROM sales s
JOIN product_details d
ON s.prod_id = d.product_id
GROUP BY d.product_name;
```
<img width="314" height="338" alt="image" src="https://github.com/user-attachments/assets/3e68f4e1-762b-4581-b4d4-e6512a1c32a8" />

2. What is the total generated revenue for all products before discounts?

```
SELECT d.product_name, SUM(s.qty * s.price) AS total_revenue
FROM sales s
JOIN product_details d
ON s.prod_id = d.product_id
GROUP BY d.product_name;
```
<img width="338" height="337" alt="image" src="https://github.com/user-attachments/assets/7cc5c248-9c1a-49cb-b966-74ad8d8d3320" />

3. What was the total discount amount for all products?

```
SELECT d.product_name, ROUND(SUM(s.discount/100::NUMERIC * s.price * s.qty),2) AS total_discounts
FROM sales s
JOIN product_details d
ON s.prod_id = d.product_id
GROUP BY d.product_name;
```
<img width="350" height="336" alt="image" src="https://github.com/user-attachments/assets/eab03fb0-d52a-4b84-9646-274bd53e4c4f" />

4. How many unique transactions were there?

```
SELECT COUNT(DISTINCT txn_id) AS unique_transactions
FROM sales;
```
<img width="185" height="61" alt="image" src="https://github.com/user-attachments/assets/909aeb7a-791d-4eb2-94ce-7e6f797cce14" />

5. What is the average unique products purchased in each transaction?

```
SELECT ROUND(AVG(uniq_prod),2) AS avg_unique_prod
FROM(
SELECT COUNT(DISTINCT prod_id) AS uniq_prod
FROM sales
GROUP BY txn_id
) a;
```
<img width="165" height="64" alt="image" src="https://github.com/user-attachments/assets/509b2db2-f493-479e-a620-c3125f0654ad" />

6. What are the 25th, 50th and 75th percentile values for the revenue per transaction?

```
WITH rev_txn AS
(
SELECT txn_id, ROUND(SUM((100 - discount)/100::NUMERIC * price * qty),2) AS revenue
FROM sales 
GROUP BY txn_id
)

SELECT
PERCENTILE_DISC(0.25) WITHIN GROUP (ORDER BY revenue ASC) AS pct25_revenue,
PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY revenue ASC) AS pct50_revenue,
PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY revenue ASC) AS pct75_revenue
FROM rev_txn;
```
<img width="371" height="62" alt="image" src="https://github.com/user-attachments/assets/a75c645f-74ec-4b23-b806-6fa0ca676f9c" />

7. What is the average discount value per transaction?

```
WITH discount_txn AS
(
SELECT txn_id, ROUND(SUM(discount/100::NUMERIC * price * qty),2) AS discount_amt
FROM sales 
GROUP BY txn_id
)

SELECT
PERCENTILE_DISC(0.25) WITHIN GROUP (ORDER BY discount_amt ASC) AS pct25_discount,
PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY discount_amt ASC) AS pct50_discount,
PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY discount_amt ASC) AS pct75_discount
FROM discount_txn;
```
<img width="381" height="67" alt="image" src="https://github.com/user-attachments/assets/c2294f1d-87c5-488e-b45f-9f40368fc84c" />

8. What is the percentage split of all transactions for members vs non-members?

```
WITH txn_count AS
(
SELECT member, COUNT(DISTINCT txn_id) AS transactions
FROM sales
GROUP BY member
)

SELECT member, transactions, ROUND(transactions::NUMERIC * 100 / SUM(transactions) OVER(),2) AS percentage_split
FROM txn_count
GROUP BY member, transactions;
```
<img width="334" height="85" alt="image" src="https://github.com/user-attachments/assets/cc25a502-d093-459c-9a05-59676ec7fdcc" />

9. What is the average revenue for member transactions and non-member transactions?

```
WITH total_revenue AS
(
SELECT member, SUM((100 - discount)/100::NUMERIC * price * qty) AS revenue
FROM sales 
GROUP BY member
),
txn_count AS
(
SELECT member, COUNT(DISTINCT txn_id) AS transactions
FROM sales
GROUP BY member
)

SELECT t.member, ROUND((r.revenue / t.transactions),2) AS avg_revenue
FROM total_revenue r
JOIN txn_count t ON r.member = t.member;
```
<img width="215" height="85" alt="image" src="https://github.com/user-attachments/assets/709306df-d14c-4bcc-b4a0-e1e965ad8308" />

10. What are the top 3 products by total revenue before discount?

```
SELECT d.product_name, SUM(s.price * s.qty) AS total_revenue
FROM sales s
JOIN product_details d
ON s.prod_id = d.product_id
GROUP BY d.product_name
ORDER BY total_revenue DESC
LIMIT 3;
```
<img width="326" height="110" alt="image" src="https://github.com/user-attachments/assets/1ff6cc17-d829-448a-afa4-d3ff51e8914d" />

11. What is the total quantity, revenue and discount for each segment?

```
SELECT d.segment_name, SUM(s.qty) AS total_quantity, SUM(s.price * s.qty) AS total_revenue, SUM(s.price * s.qty * s.discount / 100) AS total_discount
FROM sales s
JOIN product_details d
ON s.prod_id = d.product_id
GROUP BY d.segment_name;
```
<img width="496" height="135" alt="image" src="https://github.com/user-attachments/assets/d0a0e5b6-21d2-428d-b5f5-b0fa56ebc491" />

12. What is the top selling product for each segment?

```
WITH product_sales AS
(
SELECT d.segment_name, d.product_name, SUM(s.qty) AS total_quantity
FROM sales s
JOIN product_details d
ON s.prod_id = d.product_id
GROUP BY d.segment_name, d.product_name
)

SELECT segment_name, product_name, total_quantity
FROM 
(
SELECT segment_name, product_name, total_quantity, ROW_NUMBER() OVER(PARTITION BY segment_name ORDER BY total_quantity DESC) AS ranking
FROM product_sales
)
WHERE ranking = 1
ORDER BY segment_name;
```
<img width="475" height="134" alt="image" src="https://github.com/user-attachments/assets/66de19a3-d790-47bb-9dca-b672ece799b2" />

13. What is the total quantity, revenue and discount for each category?

```
SELECT d.category_name, SUM(s.qty) AS total_quantity, SUM(s.price * s.qty) AS total_revenue, SUM(s.price * s.qty * s.discount / 100) AS total_discount
FROM sales s
JOIN product_details d
ON s.prod_id = d.product_id
GROUP BY d.category_name;
```
<img width="495" height="84" alt="image" src="https://github.com/user-attachments/assets/a8e58404-5e28-47a8-aed7-6dd7fd7d0762" />

14. What is the top selling product for each category?

```
WITH product_sales2 AS
(
SELECT d.category_name, d.product_name, SUM(s.qty) AS total_quantity
FROM sales s
JOIN product_details d
ON s.prod_id = d.product_id
GROUP BY d.category_name, d.product_name
)

SELECT category_name, product_name, total_quantity
FROM 
(
SELECT category_name, product_name, total_quantity, ROW_NUMBER() OVER(PARTITION BY category_name ORDER BY total_quantity DESC) AS ranking
FROM product_sales2
)
WHERE ranking = 1
ORDER BY category_name;
```
<img width="525" height="83" alt="image" src="https://github.com/user-attachments/assets/98806830-8bc1-4e71-bfc4-4d032f21b503" />

15. What is the percentage split of revenue by product for each segment?

```
WITH total_revenue AS
(
SELECT segment_name, d.product_name, SUM(s.qty * s.price) AS revenue
FROM product_details d
JOIN sales s
ON d.product_id = s.prod_id
GROUP BY segment_name, d.product_name
)

SELECT segment_name, product_name, revenue, ROUND(SUM(revenue)::NUMERIC / SUM(revenue) OVER (PARTITION BY segment_name),2) AS pct_split
FROM total_revenue
GROUP BY segment_name, product_name, revenue;
```
<img width="571" height="334" alt="image" src="https://github.com/user-attachments/assets/b95f2502-fb50-4f5a-83a7-bf1e0e63d904" />

16. What is the percentage split of revenue by segment for each category?

```
WITH total_revenue2 AS
(
SELECT category_name, segment_name, SUM(s.qty * s.price) AS revenue
FROM product_details d
JOIN sales s
ON d.product_id = s.prod_id
GROUP BY category_name, segment_name
)

SELECT category_name, segment_name, revenue, ROUND(revenue::NUMERIC / SUM(revenue) OVER (PARTITION BY category_name),2) AS pct_split
FROM total_revenue2
GROUP BY category_name, segment_name, revenue;
```
<img width="472" height="138" alt="image" src="https://github.com/user-attachments/assets/9dc4946d-4794-4294-a9ae-321ebdc689e5" />

17. What is the percentage split of total revenue by category?

```
WITH total_revenue3 AS
(
SELECT category_name, SUM(s.qty * s.price) AS revenue
FROM product_details d
JOIN sales s
ON d.product_id = s.prod_id
GROUP BY category_name
)

SELECT category_name, revenue, ROUND(revenue::NUMERIC / SUM(revenue) OVER(),2) AS pct_split
FROM total_revenue3
GROUP BY category_name, revenue;
```
<img width="335" height="87" alt="image" src="https://github.com/user-attachments/assets/74ee919a-d696-400b-9060-1bb1353b4c6f" />

18. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

```
WITH products AS
(
SELECT product_name, COUNT(DISTINCT txn_id) AS product_transactions
FROM sales s
JOIN product_details d
ON s.prod_id = d.product_id
GROUP BY product_name;
),
txns AS
(
SELECT COUNT(DISTINCT txn_id) AS total_transactions
FROM sales
)

SELECT product_name, product_transactions, total_transactions, ROUND(product_transactions::NUMERIC / total_transactions,2) AS penetration
FROM products 
CROSS JOIN txns;
```
<img width="646" height="334" alt="image" src="https://github.com/user-attachments/assets/02fdd90f-5313-418d-ad67-fd8a71c17b85" />

19. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

```
WITH qualified_txns AS
(
SELECT txn_id, COUNT(DISTINCT product_name) AS product_count
FROM sales s
JOIN product_details d
ON s.prod_id = d.product_id
WHERE qty >= 1
GROUP BY txn_id
HAVING COUNT(DISTINCT product_name) >= 3
ORDER BY txn_id
),
products AS
(
SELECT s.txn_id, s.prod_id, d.product_name
FROM sales s
JOIN product_details d
ON s.prod_id = d.product_id
JOIN qualified_txns q
ON q.txn_id = s.txn_id
WHERE s.qty >= 1
GROUP BY s.txn_id, s.prod_id, d.product_name
)

SELECT CONCAT(p1.product_name, ' + ', p2.product_name, ' + ', p3.product_name) AS combination, COUNT(*) AS frequency
FROM products p1
JOIN products p2
ON p1.txn_id = p2.txn_id
AND p1.prod_id < p2.prod_id
JOIN products p3
ON p2.txn_id = p3.txn_id
AND p2.prod_id < p3.prod_id
GROUP BY combination
ORDER BY frequency DESC
LIMIT 1;
```
<img width="636" height="63" alt="image" src="https://github.com/user-attachments/assets/6952609e-dc98-4feb-bbc0-2d02480b5639" />

20. Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values. Imagine that the Chief Financial Officer (which is also Danny) has asked for all of these questions at the end of every month. He first wants you to generate the data for January only - but then he also wants you to demonstrate that you can easily run the samne analysis for February without many changes (if at all). Feel free to split up your final outputs into as many tables as you need - but be sure to explicitly reference which table outputs relate to which question for full marks :)

```
DROP TABLE IF EXISTS report_month;

CREATE TEMP TABLE report_month AS
SELECT 
'2021-01-01'::DATE AS start_date,
'2021-02-01'::DATE AS end_date;
```
20a. Monthly High Level Sales Analysis

```
SELECT SUM(s.qty) AS total_quantity, SUM(s.price * s.qty) total_revenue, ROUND(SUM(s.discount/100::NUMERIC * s.price * s.qty),2) AS total_discount
FROM sales s
CROSS JOIN report_month r
WHERE s.start_txn_time >= r.start_date
AND s.start_txn_time < r.end_date;
```
<img width="353" height="64" alt="image" src="https://github.com/user-attachments/assets/58dfdc65-2408-4184-b0b5-fca6fee62df9" />

20b. Monthly Transaction Analysis

```
SELECT COUNT(DISTINCT txn_id) AS unique_transactions, ROUND(AVG(unique_prod),2) AS avg_unique_prod
FROM
(
SELECT txn_id, COUNT(DISTINCT prod_id) AS unique_prod
FROM sales s
CROSS JOIN report_month r
WHERE s.start_txn_time >= r.start_date
AND s.start_txn_time < r.end_date
GROUP BY txn_id
) a;
```
<img width="304" height="68" alt="image" src="https://github.com/user-attachments/assets/40861b89-5ea6-41dd-80ba-28aaa4206c8f" />
