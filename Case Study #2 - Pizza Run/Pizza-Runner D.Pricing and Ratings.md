1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
```
SELECT SUM(CASE WHEN pizza_name = 'Meatlovers' THEN 12 WHEN pizza_name = 'Vegetarian' THEN 10 END) AS total_money_made
FROM customer_orders2 c
JOIN runner_orders2 r
ON c.order_id = r.order_id
JOIN pizza_names p 
ON c.pizza_id = p.pizza_id
WHERE r.cancellation IS NULL;
```
<img width="174" height="67" alt="image" src="https://github.com/user-attachments/assets/b51f636e-59bc-43ca-9d3e-7f1f9ced1567" />

--What if there was an additional $1 charge for any pizza extras?

--Add cheese is $1 extra
```
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
```
<img width="143" height="63" alt="image" src="https://github.com/user-attachments/assets/95a2e5ba-656d-4cdb-8c18-f8b098b708b7" />

2. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
```
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
```
<img width="437" height="283" alt="image" src="https://github.com/user-attachments/assets/a9d8935b-21ec-4e4a-a16d-e27877c3bb9c" />

3.Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
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

```
SELECT c.customer_id, c.order_id, r.runner_id, ra.rating, c.order_time, r.pickup_time, (r.pickup_time - c.order_time) AS time_btwn, 
r.duration, CONCAT(ROUND((60*r.distance/r.duration)::NUMERIC,2),'km/h') AS speed, COUNT(c.pizza_id) AS no_of_pizzas
FROM customer_orders2 c
JOIN runner_orders2 r
ON c.order_id = r.order_id
JOIN ratings ra
ON c.order_id = ra.order_id
GROUP BY c.customer_id, c.order_id, r.runner_id, ra.rating, c.order_time, r.pickup_time, r.duration, r.distance
ORDER BY order_id;
```
<img width="1095" height="287" alt="image" src="https://github.com/user-attachments/assets/d9b49ae9-182e-445f-a5b5-1a975770222d" />

4.If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
```
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
SELECT CONCAT('$',(total_revenue - runner_payment)) AS profit
FROM total_profit;
```
<img width="98" height="68" alt="image" src="https://github.com/user-attachments/assets/017db3dd-0a2e-4065-8367-496ddc526f68" />
