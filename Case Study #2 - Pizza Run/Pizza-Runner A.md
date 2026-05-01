Need to clean data in the customer_orders and runner_orders table as values in certain columns are not consistent. For example, the extras column in customer_orders has 'null', NULL and a blank ' '.

The data will be cleaned to improve consistency in the data.

-- Cleaning customer_orders
```
DROP TABLE IF EXISTS customer_orders2;
CREATE TEMPORARY TABLE customer_orders2 AS
(
SELECT order_id, customer_id, pizza_id, 
CASE WHEN exclusions = '' THEN NULL 
WHEN exclusions = 'null' THEN NULL
ELSE exclusions END AS exclusions,
CASE WHEN extras = '' THEN NULL
WHEN extras = 'null' THEN NULL
WHEN extras = 'NaN' THEN NULL 
ELSE extras END AS extras,
order_time
FROM customer_orders
);
```
-- Cleaning runner_orders
```
DROP TABLE IF EXISTS runner_orders2;
CREATE TEMPORARY TABLE runner_orders2 AS
(
SELECT order_id, runner_id,
CAST(CASE WHEN pickup_time = 'null' THEN NULL ELSE pickup_time END AS DATETIME) AS pickup_time,
CASE WHEN distance = 'null' THEN NULL ELSE distance END AS distance,
CASE WHEN duration = 'null' THEN NULL ELSE duration END AS duration,
CASE WHEN cancellation IN ('null', '', 'NaN') THEN NULL ELSE cancellation END AS cancellation
FROM runner_orders
);
```

-- 1. How many pizzas were ordered?
```
SELECT COUNT(*) as number_of_pizzas
FROM customer_orders2;
```
<img width="130" height="40" alt="image" src="https://github.com/user-attachments/assets/40312362-8be6-4671-94ed-8b5debd6d84c" />

-- 2. How many unique customer orders were made?
```
SELECT COUNT(DISTINCT order_id) as unique_orders
FROM customer_orders2;
```
<img width="110" height="37" alt="image" src="https://github.com/user-attachments/assets/0808f7ae-2a82-4497-a4d3-523935841e42" />

-- 3. How many successful orders were delivered by each runner?
```
SELECT runner_id, COUNT(*) as successful_deliveries
FROM runner_orders2
WHERE cancellation IS NULL
GROUP BY runner_id;
```
<img width="203" height="72" alt="image" src="https://github.com/user-attachments/assets/ab22fc8f-5f91-44a0-80a1-c61a9270e728" />

-- 4. How many of each type of pizza was delivered?
```
SELECT pizza_name, COUNT(*) AS pizza_delivered
FROM pizza_names n
JOIN customer_orders2 c 
ON n.pizza_id = c.pizza_id
JOIN runner_orders2 r
ON r.order_id =  c.order_id
WHERE cancellation IS NULL
GROUP BY pizza_name;
```
<img width="187" height="55" alt="image" src="https://github.com/user-attachments/assets/e9cade5c-c4ff-4c11-a125-b505bdb161be" />

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
```
SELECT c.customer_id,  COUNT(CASE WHEN n.pizza_name = 'Vegetarian' THEN n.pizza_name ELSE NULL END) as vegetarian_count,
COUNT(CASE WHEN n.pizza_name = 'Meatlovers' THEN n.pizza_name ELSE NULL END) as meatlovers_count
FROM pizza_names n
JOIN customer_orders2 c 
ON n.pizza_id = c.pizza_id
GROUP BY c.customer_id;
```
<img width="305" height="109" alt="image" src="https://github.com/user-attachments/assets/9ed725ee-9d54-482c-a1c5-28be7285690e" />

-- 6. What was the maximum number of pizzas delivered in a single order?
```
SELECT c.order_id, COUNT(c.pizza_id) AS no_of_pizzas
FROM pizza_names n
JOIN customer_orders2 c 
ON n.pizza_id = c.pizza_id
JOIN runner_orders2 r
ON r.order_id =  c.order_id
WHERE cancellation IS NULL
GROUP BY order_id
ORDER BY no_of_pizzas DESC
LIMIT 1;
```
<img width="161" height="40" alt="image" src="https://github.com/user-attachments/assets/3460777d-46d4-446e-81e5-0917cc3423ae" />

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
```
SELECT customer_id, COUNT(CASE WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN c.order_id ELSE NULL END) as one_change,
COUNT(CASE WHEN exclusions IS NULL AND extras IS NULL THEN c.order_id ELSE NULL END) no_changes
FROM customer_orders2 c
JOIN runner_orders2 r
ON c.order_id = r.order_id
WHERE cancellation IS NULL
GROUP BY customer_id;
```
<img width="251" height="105" alt="image" src="https://github.com/user-attachments/assets/2ec35538-40e3-49f0-b004-c4b2f2702786" />

-- 8. How many pizzas were delivered that had both exclusions and extras?
```
SELECT COUNT(CASE WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN c.order_id ELSE NULL END) as both_delivered
FROM customer_orders2 c
JOIN runner_orders2 r
ON c.order_id = r.order_id
WHERE cancellation IS NULL;
```
<img width="115" height="33" alt="image" src="https://github.com/user-attachments/assets/1814a675-0689-4d25-89c8-ad1cf8989147" />

-- 9.  What was the total volume of pizzas ordered for each hour of the day?
```
SELECT EXTRACT(HOUR FROM order_time) as hour_of_day, COUNT(pizza_id) as volume_of_pizza
FROM customer_orders2
GROUP BY hour_of_day
ORDER BY hour_of_day;
```
<img width="200" height="122" alt="image" src="https://github.com/user-attachments/assets/cd2ce2b6-4851-4eae-9655-b4a8ce3eb3bd" />

-- 10. What was the volume of orders for each day of the week?
```
SELECT EXTRACT(DAY FROM order_time) as day, COUNT(pizza_id) as volume_of_orders
FROM customer_orders2
GROUP BY day;
```
<img width="169" height="140" alt="image" src="https://github.com/user-attachments/assets/854f3ddf-8b70-4adf-b366-c09bb10b5b8d" />


