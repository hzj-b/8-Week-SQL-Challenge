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

--If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

SELECT SUM(CASE WHEN pizza_name = 'Meatlovers' THEN 12 WHEN pizza_name = 'Vegetarian' THEN 10 END) AS total_money_made
FROM customer_orders2 c
JOIN runner_orders2 r
ON c.order_id = r.order_id
JOIN pizza_names p 
ON c.pizza_id = p.pizza_id
WHERE r.cancellation IS NULL;

--What if there was an additional $1 charge for any pizza extras?
--Add cheese is $1 extra

SELECT 
	 SUM(CASE WHEN pizza_name = 'Meatlovers' THEN 12 WHEN pizza_name = 'Vegetarian' THEN 10 END
	+ COALESCE(
		array_length(string_to_array(extras,','),1),0
	)
	+ CASE
		WHEN 4 = ANY(string_to_array(extras,',')::INT[])
		THEN 1
		ELSE 0
      END
) AS total_amount
FROM customer_orders2 c
JOIN runner_orders2 r
    ON r.order_id = c.order_id
JOIN pizza_names p
    ON p.pizza_id = c.pizza_id
WHERE r.cancellation IS NULL;

--The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

DROP TABLE IF EXISTS ratings;
CREATE TABLE ratings (
rating_id INT,
order_id INT,
customer_id INT,
runner_id INT,
rating INT
);

INSERT INTO ratings (
rating_id,
order_id, 
customer_id, 
runner_id, 
rating 
) VALUES 
('1','1','101','1','1'),
('2','2','101','1','2'),
('3','3','102','1','3'),
('4','4','103','2','4'),
('5','5','104','3','5'),
('6','6','101','3','4'),
('7','7','105','2','3'),
('8','8','102','2','2'),
('9','9','103','2','4'),
('10','10','104','1','1');

SELECT *
FROM ratings;


--Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
--customer_id
--order_id
--runner_id
--rating
--order_time
--pickup_time
--Time between order and pickup
--Delivery duration
--Average speed
--Total number of pizzas

SELECT c.customer_id, c.order_id, r.runner_id, ra.rating, c.order_time, r.pickup_time, (r.pickup_time - c.order_time) AS time_btwn, 
r.duration, ROUND((60*r.distance/r.duration)::NUMERIC,2)AS speed, COUNT(c.pizza_id) AS no_of_pizzas
FROM customer_orders2 c
JOIN runner_orders2 r
ON c.order_id = r.order_id
JOIN ratings ra
ON c.order_id = ra.order_id
GROUP BY c.customer_id, c.order_id, r.runner_id, ra.rating, c.order_time, r.pickup_time, r.duration, r.distance
ORDER BY order_id;

--If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

WITH total_profit AS (
SELECT 
SUM(CASE
		WHEN
			pizza_name = 'Meatlovers' THEN 12
		WHEN 
			pizza_name = 'Vegetarian' THEN 10
		ELSE
			NULL
	END) AS total_revenue,
SUM(r.distance) AS total_distance,
SUM(r.distance)*0.3 AS runner_payment
FROM pizza_names p
JOIN customer_orders2 c
ON p.pizza_id = c.pizza_id
JOIN runner_orders2 r 
ON c.order_id = r.order_id
WHERE r.cancellation IS NULL
)

SELECT (total_revenue - runner_payment) AS leftovers
FROM total_profit;