SET search_path = pizza_runner;

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

SELECT * 
FROM customer_orders2; 

SELECT * 
FROM runner_orders;

DROP TABLE IF EXISTS runner_orders2;
CREATE TEMPORARY TABLE runner_orders2 AS
(
SELECT order_id, runner_id,
CAST(CASE WHEN pickup_time = 'null' THEN NULL ELSE pickup_time END AS TIMESTAMP) AS pickup_time,
CASE WHEN distance = 'null' THEN NULL ELSE CAST(REGEXP_REPLACE(distance, '[a-z]+', '') AS FLOAT) END AS distance,
CASE WHEN duration = 'null' THEN NULL ELSE CAST(REGEXP_REPLACE(duration, '[a-z]+', '') AS INTEGER) END AS duration,
CASE WHEN cancellation IN ('null', '', 'NaN') THEN NULL ELSE cancellation END AS cancellation
FROM runner_orders
);

SELECT*
FROM runner_orders2;

-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT *
FROM runners;

SELECT (registration_date - DATE '2021-01-01') / 7 AS week, COUNT(runner_id)
FROM runners
GROUP BY week
ORDER BY week;

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

WITH order_times AS
(
SELECT DISTINCT r.order_id, r.runner_id, EXTRACT(EPOCH FROM(r.pickup_time - c.order_time)) / 60 AS arrival_duration
FROM runner_orders2 r 
JOIN customer_orders2 c
ON r.order_id = c.order_id
WHERE pickup_time IS NOT NULL
)

SELECT runner_id, CONCAT(ROUND(AVG(arrival_duration),2),' minutes') AS avg_arrival_time
FROM order_times
GROUP BY runner_id;

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH order_times AS
(
SELECT DISTINCT r.order_id, r.runner_id, EXTRACT(EPOCH FROM(r.pickup_time - c.order_time)) / 60 AS arrival_duration
FROM runner_orders2 r 
JOIN customer_orders2 c
ON r.order_id = c.order_id
WHERE pickup_time IS NOT NULL
),
pizza_count AS
(
SELECT order_id, COUNT(*) AS no_of_pizzas
FROM customer_orders2 
GROUP BY order_id
)

SELECT p.no_of_pizzas, CONCAT(ROUND(AVG(o.arrival_duration),2),' minutes')
FROM order_times o
JOIN pizza_count p 
ON o.order_id = p.order_id
GROUP BY p.no_of_pizzas
ORDER BY p.no_of_pizzas;

-- What was the average distance travelled for each customer?

WITH distance_travelled AS
(
SELECT DISTINCT r.order_id, r.runner_id, customer_id, distance 
FROM runner_orders2 r 
JOIN customer_orders2 c
ON r.order_id = c.order_id
WHERE pickup_time IS NOT NULL
)

SELECT customer_id, CONCAT(AVG(distance),'km') AS avg_distance
FROM distance_travelled
GROUP BY customer_id
ORDER BY customer_id;

-- What was the difference between the longest and shortest delivery times for all orders?

SELECT MAX(duration) - MIN(duration) AS delivery_time_difference
FROM runner_orders2
WHERE cancellation IS NULL; 

-- What was the average speed for each runner for each delivery and do you notice any trend for these values?


SELECT r.order_id, r.runner_id, CONCAT(ROUND(((r.distance::NUMERIC / r.duration) * 60),2),' km/h') AS speed
FROM customer_orders2 c
JOIN runner_orders2 r
ON c.order_id = r.order_id;

--What is the successful delivery percentage for each runner?

SELECT runner_id, CONCAT((ROUND(SUM(CASE WHEN cancellation IS NULL THEN 1 ELSE 0 END)::NUMERIC * 100 / COUNT(order_id),2)),'%') AS success_pct
FROM runner_orders2
GROUP BY runner_id;
