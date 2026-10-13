1. How many unique nodes are there on the Data Bank system?
```
SELECT COUNT(DISTINCT node_id) as unique_nodes
FROM customer_nodes;
```
<img width="148" height="62" alt="image" src="https://github.com/user-attachments/assets/e085f3e1-1843-40b6-92b8-7a9f39825af6" />

2. What is the number of nodes per region?
```
SELECT region_id, COUNT(node_id)
FROM customer_nodes
GROUP BY region_id;
```
<img width="183" height="171" alt="image" src="https://github.com/user-attachments/assets/837f7de9-f182-4063-a54c-66241c7512b8" />

3. How many customers are allocated to each region?
```
SELECT region_id, COUNT(DISTINCT customer_id) AS no_of_customers
FROM customer_nodes
GROUP BY region_id;
```
<img width="239" height="162" alt="image" src="https://github.com/user-attachments/assets/1aa29cfe-4ba8-489c-b28c-2a21262433ea" />

4. How many days on average are customers reallocated to a different node?
```
WITH CTE AS
(
SELECT customer_id, c.region_id, r.region_name, node_id, start_date, LAG(start_date,1) OVER(PARTITION BY customer_id ORDER BY start_date) as prev_start
FROM customer_nodes c 
JOIN regions r
ON r.region_id = c.region_id
ORDER BY customer_id
)

SELECT ROUND(AVG(start_date - prev_start),0) AS avg_reallocate
FROM CTE
WHERE prev_start IS NOT NULL;
```
<img width="148" height="63" alt="image" src="https://github.com/user-attachments/assets/2dc74aec-2f4b-4e70-81ca-6d5806c7c79e" />

5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
```
WITH CTE AS
(
SELECT customer_id, c.region_id, r.region_name, node_id, start_date, LAG(start_date,1) OVER(PARTITION BY customer_id ORDER BY start_date) as prev_start
FROM customer_nodes c 
JOIN regions r
ON r.region_id = c.region_id
ORDER BY customer_id
),
reallocation AS
(
SELECT region_name, (start_date - prev_start) AS reallocate_diff
FROM CTE
WHERE prev_start IS NOT NULL
)

SELECT region_name, PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY reallocate_diff) AS median_days, 
					PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY reallocate_diff) AS pct80_days,
					PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY reallocate_diff) AS pct95_days
FROM reallocation
GROUP BY region_name;
```
<img width="546" height="165" alt="image" src="https://github.com/user-attachments/assets/2c9e942a-d643-40a6-abfa-c74ae35dc4b2" />

6. What is the unique count and total amount for each transaction type?
```
SELECT txn_type, COUNT(txn_type), SUM(txn_amount) AS totaL_amt
FROM customer_transactions
GROUP BY txn_type;
```
<img width="328" height="110" alt="image" src="https://github.com/user-attachments/assets/340a1bec-23a3-4eb7-8b6b-a912d4e12f92" />

7. What is the average total historical deposit counts and amounts for all customers?
```
SELECT COUNT(txn_type) / COUNT(DISTINCT customer_id) AS avg_deposit_count, '$' || ROUND(AVG(txn_amount),2) AS avg_deposit_amt
FROM customer_transactions
WHERE txn_type = 'deposit';
```
<img width="290" height="59" alt="image" src="https://github.com/user-attachments/assets/33a44778-ee16-472e-b2d2-61434d6d3f60" />

8. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
```
WITH monthly AS
(
SELECT customer_id, EXTRACT(MONTH FROM txn_date) AS month, 
SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) as deposit_count,
SUM(CASE WHEN txn_type = 'purchase' OR txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS purchase_or_withdrawal
FROM customer_transactions
GROUP BY customer_id, EXTRACT(MONTH FROM txn_date)
ORDER BY 1,2
)

SELECT month, COUNT(customer_id) AS no_of_customers
FROM monthly
WHERE deposit_count > 1
AND purchase_or_withdrawal >= 1
GROUP BY month;
```
<img width="239" height="138" alt="image" src="https://github.com/user-attachments/assets/ce20e0a3-765f-4444-a1e5-9f22f1a09d7b" />

9. What is the closing balance for each customer at the end of the month?
```
WITH running_total AS
(
SELECT customer_id, DATE_TRUNC('month', txn_date) AS month, txn_type, txn_date,
SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) OVER(PARTITION BY customer_id ORDER BY txn_date) AS running_sum
FROM customer_transactions
),
ranking AS
(
SELECT *, ROW_NUMBER() OVER(PARTITION BY customer_id, month ORDER BY txn_date DESC) AS rn
FROM running_total
)
SELECT customer_id, EXTRACT(MONTH FROM month) AS month, running_sum AS closing_balance
FROM ranking
WHERE rn = 1;
```

10. What is the percentage of customers who increase their closing balance by more than 5%?
```
WITH running_total AS
(
SELECT customer_id, DATE_TRUNC('month', txn_date) AS month, txn_type, txn_date,
SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) OVER(PARTITION BY customer_id ORDER BY txn_date) AS running_sum
FROM customer_transactions
),
ranking AS
(
SELECT *, ROW_NUMBER() OVER(PARTITION BY customer_id, month ORDER BY txn_date DESC) AS rn
FROM running_total
),
closing AS
(
SELECT customer_id, EXTRACT(MONTH FROM month) AS month, running_sum AS closing_balance
FROM ranking
WHERE rn = 1
),
growth AS
(
SELECT *, LAG(closing_balance,1) OVER(PARTITION BY customer_id ORDER BY month) AS prev_closing
FROM closing
)
SELECT ROUND(COUNT(DISTINCT CASE WHEN prev_closing IS NOT NULL AND prev_closing <> 0 AND (closing_balance - prev_closing) / prev_closing > 0.05 THEN customer_id END)::NUMERIC * 100 / COUNT(DISTINCT customer_id),2) || '%' AS pct
FROM growth;
```
<img width="151" height="65" alt="image" src="https://github.com/user-attachments/assets/86f9f8af-b21c-4e20-a1cd-c6118a3df5a2" />

To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

--Option 1: data is allocated based off the amount of money at the end of the previous month
--Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
--Option 3: data is updated real-time
--For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:
--running customer balance column that includes the impact each transaction
--customer balance at the end of each month
--minimum, average and maximum values of the running balance for each customer
--	Using all of the data available - how much data would have been required for each option on a monthly basis?


