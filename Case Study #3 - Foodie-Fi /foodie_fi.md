-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

-- Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
```
SELECT *
FROM subscriptions s 
JOIN plans p
	ON p.plan_id = s.plan_id
WHERE customer_id IN ('1','2','11','13','15','16','18','19')
ORDER BY customer_id;
```
<img width="606" height="539" alt="image" src="https://github.com/user-attachments/assets/b7892796-a406-4a32-b4b1-8a9da007d92c" />

-- How many customers has Foodie-Fi ever had?
```
SELECT COUNT(DISTINCT customer_id)
FROM subscriptions;
```
<img width="100" height="63" alt="image" src="https://github.com/user-attachments/assets/ef57aa59-c943-4870-a2cb-09b9ebfb3c99" />

-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
```
SELECT DATE_TRUNC('month', start_date) AS mth_start, COUNT(*)
FROM subscriptions
WHERE plan_id = 0
GROUP BY mth_start
ORDER BY mth_start;
```
<img width="269" height="337" alt="image" src="https://github.com/user-attachments/assets/2c2c50e1-9e04-4812-b622-74007579ad23" />

-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
```
SELECT
    p.plan_name,
    COUNT(*) AS event_count
FROM subscriptions s
JOIN plans p
    ON s.plan_id = p.plan_id
WHERE s.start_date >= '2021-01-01'
GROUP BY p.plan_name
ORDER BY event_count DESC;
```
<img width="282" height="132" alt="image" src="https://github.com/user-attachments/assets/edd95d23-8c14-4f5d-92ec-7a2c95320ba9" />

-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
```
SELECT COUNT(CASE 
			WHEN plan_id = 4 THEN customer_id ELSE NULL END) AS churn_count,
		ROUND(COUNT
		(CASE 
			WHEN plan_id = 4 THEN customer_id ELSE NULL END)::NUMERIC*100 / COUNT(DISTINCT(customer_id)),1) as pct_customers
FROM subscriptions;

WITH customer_churn AS (
    SELECT 
        customer_id,
        MAX(CASE WHEN plan_id = 4 THEN 1 ELSE 0 END) AS is_churned
    FROM subscriptions
    GROUP BY customer_id
)
SELECT
    SUM(is_churned) AS churned_customers,
    ROUND(
        SUM(is_churned)::NUMERIC * 100 / COUNT(*),
        1
    ) AS pct_customers
FROM customer_churn;
```
<img width="288" height="60" alt="image" src="https://github.com/user-attachments/assets/e42e52f2-30b0-490a-b027-19c8225a2705" />

-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
```
WITH CTE AS
(
SELECT customer_id, plan_id, LEAD(plan_id,1) OVER (PARTITION BY customer_id) as next_plan
FROM subscriptions
)

SELECT COUNT(DISTINCT customer_id) AS churn_straight, ROUND(COUNT(DISTINCT customer_id)::NUMERIC * 100 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions),0) AS churn_straight_pct
FROM CTE
WHERE plan_id = '0'
AND next_plan = '4';
```
<img width="279" height="60" alt="image" src="https://github.com/user-attachments/assets/fd547a13-2a0e-4fd3-98cd-58a187257125" />

-- What is the number and percentage of customer plans after their initial free trial?
```
WITH CTE2 AS
(
SELECT customer_id, plan_id, LEAD(plan_id,1) OVER (PARTITION BY customer_id ORDER BY start_date) as next_plan
FROM subscriptions s
)

SELECT p.plan_name, COUNT(next_plan) AS num_plans_after, ROUND(COUNT(*)::NUMERIC * 100/ SUM(COUNT(*)) OVER (),2) AS pct_after
FROM CTE2 c
JOIN plans p 
ON c.next_plan = p.plan_id
WHERE c.plan_id = 0
GROUP BY p.plan_name;
```
<img width="383" height="133" alt="image" src="https://github.com/user-attachments/assets/3d6e3e4d-9d0c-49a2-98b2-fa4184a2639c" />

-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
```
WITH CTE3 AS
(
SELECT customer_id, plan_id, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date DESC) as rn
FROM subscriptions
WHERE start_date <= '2020-12-31'
)

SELECT p.plan_name, COUNT(*) AS customer_count, ROUND(COUNT(*)::NUMERIC * 100 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions),2) AS pct_breakdown
FROM CTE3 c
JOIN plans p
ON c.plan_id = p.plan_id
WHERE c.rn = 1
GROUP BY p.plan_name;
```
<img width="418" height="159" alt="image" src="https://github.com/user-attachments/assets/4055af81-0838-4dae-afd0-a163bcb3c9d9" />

-- How many customers have upgraded to an annual plan in 2020?
```
WITH CTE4 AS
(
SELECT customer_id, plan_id, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date DESC) as rn
FROM subscriptions
WHERE start_date <= '2020-12-31'
)

SELECT COUNT(DISTINCT customer_id)
FROM CTE4
WHERE rn = 1
AND plan_id = 3;
```
<img width="104" height="65" alt="image" src="https://github.com/user-attachments/assets/d5af81f3-b12c-409a-8347-0aeb92784b5d" />

-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
```
WITH trial AS
(
SELECT customer_id, plan_id, start_date as trial_date
FROM subscriptions
WHERE plan_id = 0
),
annual AS
(
SELECT customer_id, plan_id, start_date as annual_join_date
FROM subscriptions
WHERE plan_id = 3
)

SELECT ROUND(AVG(annual_join_date - trial_date),0) AS avg_days
FROM trial t
JOIN annual a
ON t.customer_id = a.customer_id;
```
<img width="123" height="65" alt="image" src="https://github.com/user-attachments/assets/59bcf24a-5e3a-4cb5-aacf-f25ae17b5577" />

-- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
```
WITH trial AS
(
SELECT customer_id, plan_id, start_date as trial_date
FROM subscriptions
WHERE plan_id = 0
),
annual AS
(
SELECT customer_id, plan_id, start_date as annual_join_date
FROM subscriptions
WHERE plan_id = 3
),
cte_days AS
(
SELECT a.customer_id, annual_join_date - trial_date AS upgrade_days
FROM trial t
JOIN annual a
ON t.customer_id = a.customer_id
),
buckets AS
(
SELECT WIDTH_BUCKET(upgrade_days, 0, 360, 12) AS bucket, COUNT(*) AS customers
FROM cte_days
GROUP BY bucket
)
SELECT
	CASE
		WHEN bucket = 1 THEN '0-30 days'
		ELSE (bucket-1) * 30 + 1 || '-' || (bucket * 30) || 'days'
	END AS time_period, customers
FROM buckets
GROUP BY time_period, customers, bucket
ORDER BY bucket;
```
<img width="221" height="339" alt="image" src="https://github.com/user-attachments/assets/b89db0a5-7988-41e9-981f-e11d0e3fa5d4" />

-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
```
WITH downgrade AS
(
SELECT s.customer_id, p.plan_name, s.start_date, LAG(p.plan_name,1) OVER (PARTITION BY customer_id ORDER BY start_date ASC) AS Lag_plan
FROM subscriptions s
JOIN plans p 
ON s.plan_id = p.plan_id
WHERE s.start_date <= '2020-12-31'
)
SELECT COUNT(DISTINCT customer_id)
FROM downgrade
WHERE plan_name = 'basic monthly' AND lag_plan = 'pro monthly';
```
<img width="104" height="67" alt="image" src="https://github.com/user-attachments/assets/2157787f-5aca-4620-9504-ba479793fbef" />
