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
CASE WHEN duration = 'null' THEN NULL ELSE CAST(REGEXP_REPLACE(duration, '[a-z]+', '') AS INT) END AS duration,
CASE WHEN cancellation IN ('null', '', 'NaN') THEN NULL ELSE cancellation END AS cancellation
FROM runner_orders
);

SELECT*
FROM runner_orders2;

-- What are the standard ingredients for each pizza?

SELECT pizza_name, topping_name	
FROM pizza_names n
JOIN pizza_recipes r 
ON n.pizza_id = r.pizza_id
JOIN pizza_toppings t
ON t.topping_id = ANY(string_to_array(r.toppings, ',')::INT[]);

-- What was the most commonly added extra?

WITH common AS
(
SELECT topping_name, COUNT(topping_name) AS number_of_extras
FROM pizza_toppings t
JOIN customer_orders2 c
ON topping_id = ANY(string_to_array(extras,',')::INT[])
GROUP BY topping_name
)

SELECT topping_name, number_of_extras, rnk
FROM (
SELECT *, RANK() OVER (ORDER BY number_of_extras DESC) AS rnk
FROM common
 ) ranking
WHERE rnk = 1;

--What was the most common exclusion?

WITH exclusion AS
(
SELECT topping_name, COUNT(topping_name) AS number_of_exclusions
FROM pizza_toppings t
JOIN customer_orders2 c
ON topping_id = ANY(string_to_array(exclusions,',')::INT[])
GROUP BY topping_name
)

SELECT topping_name, number_of_exclusions, rnk
FROM (
SELECT *, RANK() OVER (ORDER BY number_of_exclusions DESC) AS rnk
FROM exclusion
 ) ranking2
WHERE rnk = 1;

--Generate an order item for each record in the customers_orders table in the format of one of the following:
--Meat Lovers
--Meat Lovers - Exclude Beef
--Meat Lovers - Extra Bacon
--Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

SELECT 
	order_id, pizza_name,
	CONCAT(
		pizza_name,
		CASE
			WHEN (
				SELECT STRING_AGG(topping_name,', ')
				FROM pizza_toppings t
				WHERE topping_id = ANY(string_to_array(c.exclusions,',')::INT[])
				)
				IS NOT NULL
			THEN CONCAT(
				' - Exclude ',
				(
					SELECT STRING_AGG(topping_name,', ')
					FROM pizza_toppings t
					WHERE topping_id = ANY(string_to_array(c.exclusions,',')::INT[])
				)
			)
			ELSE ''
		END,
		CASE
			WHEN (
				SELECT STRING_AGG(topping_name,', ')
				FROM pizza_toppings t
				WHERE topping_id = ANY(string_to_array(c.extras,',')::INT[])
				)
				IS NOT NULL
			THEN CONCAT(
				' - Extra ',
				(
				SELECT STRING_AGG(topping_name,', ')
				FROM pizza_toppings t
				WHERE topping_id = ANY(string_to_array(c.extras,',')::INT[])
				)
			)
			ELSE ''
		END
		) as order_items
FROM pizza_names p
JOIN customer_orders2 c
ON p.pizza_id = c.pizza_id
ORDER BY order_id;


--What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

WITH base AS (	
SELECT t.topping_name, COUNT(t.topping_name) as qty
FROM runner_orders2 r
JOIN customer_orders2 c
ON r.order_id = c.order_id
JOIN pizza_recipes re
ON re.pizza_id = c.pizza_id
JOIN pizza_toppings t
ON t.topping_id = ANY(string_to_array(re.toppings,',')::INT[])
WHERE r.cancellation IS NULL
GROUP BY t.topping_name
),
extra_ingredients AS (
SELECT t.topping_name, COUNT(t.topping_name) as qty
FROM runner_orders2 r
JOIN customer_orders2 c
ON r.order_id = c.order_id
JOIN pizza_toppings t
ON t.topping_id = ANY(string_to_array(c.extras,',')::INT[])
WHERE r.cancellation IS NULL
GROUP BY t.topping_name
),
excluded_ingredients AS (
SELECT t.topping_name, COUNT(t.topping_name) as qty
FROM runner_orders2 r
JOIN customer_orders2 c
ON r.order_id = c.order_id 
JOIN pizza_toppings t
ON t.topping_id = ANY(string_to_array(c.exclusions,',')::INT[])
WHERE r.cancellation IS NULL
GROUP BY t.topping_name
),
all_ingredients AS (
SELECT topping_name, qty FROM base
UNION ALL 
SELECT topping_name, qty FROM extra_ingredients
UNION ALL 
SELECT topping_name, -qty FROM excluded_ingredients
)

SELECT topping_name, SUM(qty) AS total_quantity
FROM all_ingredients
GROUP BY topping_name
ORDER BY total_quantity DESC;

