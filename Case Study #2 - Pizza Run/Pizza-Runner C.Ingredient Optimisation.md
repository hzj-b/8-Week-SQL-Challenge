This part was a lot more challenging for me and I had to spend more time on each question, especially questions 4 and 5, having troubles, getting confused with unclean formatting.

-- 1. What are the standard ingredients for each pizza?
```
SELECT pizza_name, topping_name	
FROM pizza_names n
JOIN pizza_recipes r 
ON n.pizza_id = r.pizza_id
JOIN pizza_toppings t
ON t.topping_id = ANY(string_to_array(r.toppings, ',')::INT[]);
```
<img width="244" height="388" alt="image" src="https://github.com/user-attachments/assets/1a165403-95fa-454e-9333-c50c41cb1a1f" />

-- 2. What was the most commonly added extra?
```
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
```
<img width="338" height="64" alt="image" src="https://github.com/user-attachments/assets/a042319e-30d3-420d-8e24-a0931be60b19" />

-- 3. What was the most common exclusion?
```
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
```
<img width="364" height="64" alt="image" src="https://github.com/user-attachments/assets/7ac7d1b9-a48a-4f70-b935-9fe36e0e106b" />

--4. Generate an order item for each record in the customers_orders table in the format of one of the following:
--Meat Lovers
--Meat Lovers - Exclude Beef
--Meat Lovers - Extra Bacon
--Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
```
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
```
<img width="724" height="387" alt="image" src="https://github.com/user-attachments/assets/c8dace3b-2308-496e-bf39-82208aa67e86" />

-- 5. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
```
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
```
<img width="252" height="337" alt="image" src="https://github.com/user-attachments/assets/fd7e3952-6601-412a-a641-d04829fc3814" />

