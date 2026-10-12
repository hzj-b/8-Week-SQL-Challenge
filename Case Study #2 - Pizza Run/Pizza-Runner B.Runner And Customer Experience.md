1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

```
SELECT (registration_date - DATE '2021-01-01') / 7 AS week, COUNT(runner_id)
FROM runners
GROUP BY week
ORDER BY week;
```
<img width="176" height="115" alt="image" src="https://github.com/user-attachments/assets/1e9d1d9b-22a7-43cd-b428-03520c433fd5" />

2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

```
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
```
<img width="242" height="117" alt="image" src="https://github.com/user-attachments/assets/bba925e9-2c86-4eef-afd9-5eb746b3a654" />

3. Is there any relationship between the number of pizzas and how long the order takes to prepare? 

```
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
SELECT p.no_of_pizzas, CONCAT(ROUND(AVG(o.arrival_duration),2),' minutes') AS prep_time
FROM order_times o
JOIN pizza_count p 
ON o.order_id = p.order_id
GROUP BY p.no_of_pizzas
ORDER BY p.no_of_pizzas;
```
<img width="266" height="111" alt="image" src="https://github.com/user-attachments/assets/8399dfcb-6f99-4132-8742-4851fceb6fc6" />

4. What was the average distance travelled for each customer?

```
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
```
<img width="241" height="165" alt="image" src="https://github.com/user-attachments/assets/f84b2e74-52e0-4888-ae6e-d2b4985c0c98" />

5. What was the difference between the longest and shortest delivery times for all orders?

```
SELECT MAX(duration) - MIN(duration) AS delivery_time_difference
FROM runner_orders2
WHERE cancellation IS NULL;
```
<img width="204" height="62" alt="image" src="https://github.com/user-attachments/assets/e4edcc16-5c92-4961-a95b-769ed705db1c" />

6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

```
SELECT DISTINCT r.order_id, r.runner_id, CONCAT(ROUND(((r.distance::NUMERIC / r.duration) * 60),2),' km/h') AS speed
FROM customer_orders2 c
JOIN runner_orders2 r
ON c.order_id = r.order_id;
```
<img width="293" height="287" alt="image" src="https://github.com/user-attachments/assets/19b4169e-d3a0-4cb7-8041-7c48dcdbf6af" />

7. What is the successful delivery percentage for each runner?

```
SELECT runner_id, CONCAT((ROUND(SUM(CASE WHEN cancellation IS NULL THEN 1 ELSE 0 END)::NUMERIC * 100 / COUNT(order_id),2)),'%') AS success_pct
FROM runner_orders2
GROUP BY runner_id;
```
<img width="224" height="117" alt="image" src="https://github.com/user-attachments/assets/384bd449-83db-40c4-897a-6c3e47759caf" />
