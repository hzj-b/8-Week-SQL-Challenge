SET search_path = pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  runner_id INT,
  registration_date DATE
);
INSERT INTO runners VALUES
  ('1', '2021-01-01'),
  ('2', '2021-01-03'),
  ('3', '2021-01-08'),
  ('4', '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  order_id INTEGER,
  customer_id INTEGER,
  pizza_id INTEGER,
  exclusions VARCHAR(4),
  extras VARCHAR(4),
  order_time TIMESTAMP
);

INSERT INTO customer_orders VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  order_id INTEGER,
  runner_id INTEGER,
  pickup_time VARCHAR(19),
  distance VARCHAR(7),
  duration VARCHAR(10),
  cancellation VARCHAR(23)
);

INSERT INTO runner_orders VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  pizza_id INTEGER,
  pizza_name TEXT
);

INSERT INTO pizza_names VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  pizza_id INTEGER,
  toppings TEXT
);

INSERT INTO pizza_recipes VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  topping_id INTEGER,
  topping_name TEXT
);
INSERT INTO pizza_toppings VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');

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
CASE WHEN duration = 'null' THEN NULL ELSE CAST(REGEXP_REPLACE(duration, '[a-z]+', '') AS INT) END AS duration,
CASE WHEN cancellation IN ('null', '', 'NaN') THEN NULL ELSE cancellation END AS cancellation
FROM runner_orders
);

SELECT*
FROM runner_orders2;

-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT DATE_TRUNC('week',registration_date) AS week,  COUNT(runner_id)
FROM runners
GROUP BY week;


-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT runner_id, AVG(pickup_time - order_time) AS average_time
FROM runner_orders2 r 
JOIN customer_orders2 c
ON r.order_id = c.order_id
WHERE pickup_time IS NOT NULL
GROUP BY runner_id
ORDER BY runner_id;

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH CTE AS (
SELECT c.order_id, COUNT(c.order_id) AS number_of_pizzas, order_time, pickup_time, (pickup_time - order_time) AS time_difference
FROM runner_orders2 r 
JOIN customer_orders2 c
ON r.order_id = c.order_id
WHERE pickup_time IS NOT NULL
GROUP BY c.order_id, order_time, pickup_time
)

SELECT number_of_pizzas, AVG(time_difference)
FROM CTE
GROUP BY number_of_pizzas
ORDER BY number_of_pizzas;

-- What was the average distance travelled for each customer?

SELECT customer_id, ROUND(CAST(AVG(distance) AS NUMERIC),2) AS average_distance_km
FROM customer_orders2 c
JOIN runner_orders2 r 
ON c.order_id = r.order_id
WHERE cancellation IS NULL
GROUP BY customer_id;

-- What was the difference between the longest and shortest delivery times for all orders?

SELECT MAX(duration) - MIN(duration) AS shortest_delivery_time
FROM runner_orders2
WHERE cancellation IS NULL;

-- What was the average speed for each runner for each delivery and do you notice any trend for these values?

WITH CTE3 AS
(
SELECT c.order_id, COUNT(c.order_id) AS no_of_pizzas, r.runner_id, r.distance, r.duration, ROUND(CAST((r.distance/r.duration)*60 AS NUMERIC),2) AS speed_kmh
FROM runner_orders2 r
JOIN customer_orders2 c
ON r.order_id = c.order_id
WHERE cancellation IS NULL
GROUP BY c.order_id, r.runner_id, r.distance, r.duration
)

SELECT corr(no_of_pizzas, speed_kmh)
FROM CTE3;

-- What is the successful delivery percentage for each runner?

SELECT runner_id, (SUM(CASE WHEN cancellation IS NULL THEN 1 ELSE 0 EN / COUNT(runner_id)) as pct
FROM runner_orders2
GROUP BY runner_id;
