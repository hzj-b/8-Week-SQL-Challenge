1. How many users are there?
```
SELECT COUNT(DISTINCT user_id)
FROM users;
```
<img width="104" height="58" alt="image" src="https://github.com/user-attachments/assets/64871bc7-c156-4f80-b535-78c3ed3269ff" />

2. How many cookies does each user have on average?
```
SELECT COUNT(cookie_id) / COUNT(DISTINCT user_id) AS avg_cookies
FROM users;
```
<img width="136" height="64" alt="image" src="https://github.com/user-attachments/assets/6d524e0f-8d0e-4a5c-9a50-a46e23fca41c" />

3. What is the unique number of visits by all users per month?
```
SELECT COUNT(DISTINCT visit_id) / 12 AS visits_per_month
FROM events;
```
<img width="161" height="58" alt="image" src="https://github.com/user-attachments/assets/18748d0c-a917-47c7-8d1b-829cf6ccf938" />

4. What is the number of events for each event type?
```
SELECT i.event_name, COUNT(i.event_type) AS no_of_events
FROM events e
JOIN event_identifier i ON e.event_type = i.event_type
GROUP BY i.event_type, i.event_name;
```
<img width="288" height="162" alt="image" src="https://github.com/user-attachments/assets/691b67fe-c716-44b1-bfae-7022e70869c6" />

5. What is the percentage of visits which have a purchase event?
```
SELECT ROUND(COUNT(DISTINCT CASE WHEN event_type = '3' THEN visit_id END)::NUMERIC * 100 / COUNT(DISTINCT visit_id),2) AS purchase_pct
FROM events;
```
<img width="142" height="65" alt="image" src="https://github.com/user-attachments/assets/ecaed5c7-4b7d-4610-9132-fac84dbc5c12" />

6. What is the percentage of visits which view the checkout page but do not have a purchase event?
```
WITH checklist AS
(
SELECT e.visit_id, MAX(CASE WHEN event_type = '3' THEN 1 ELSE 0 END) AS purchase, MAX(CASE WHEN e.page_id = 12 THEN 1 ELSE 0 END) AS checkout_page
FROM events e
JOIN page_hierarchy p ON e.page_id = p.page_id
GROUP BY e.visit_id
)

SELECT ROUND(COUNT(CASE WHEN purchase = '0' AND checkout_page = '1' THEN 1 END)::NUMERIC * 100 / COUNT(visit_id),2) AS pct_purchase_checkout
FROM checklist;
```
<img width="198" height="65" alt="image" src="https://github.com/user-attachments/assets/ce81e480-f2bf-4294-b93e-67b8c793ec32" />

7. What are the top 3 pages by number of views?
```
SELECT p.page_name, COUNT(e.page_id) AS no_of_views
FROM events e
JOIN page_hierarchy p
ON e.page_id = p.page_id
WHERE e.event_type = '1'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;
```
<img width="292" height="106" alt="image" src="https://github.com/user-attachments/assets/e3393b69-7efd-4b8f-b006-e839b850ce7e" />

8. What is the number of views and cart adds for each product category?
```
SELECT p.product_category, SUM(CASE WHEN event_type = '1' THEN 1 ELSE 0 END) AS page_view_count, SUM(CASE WHEN event_type = '2' THEN 1 ELSE 0 END) AS cart_add_count
FROM events e
JOIN page_hierarchy p
ON e.page_id = p.page_id
GROUP BY 1
ORDER BY 2 DESC;
```
<img width="422" height="134" alt="image" src="https://github.com/user-attachments/assets/c1618808-21df-4473-a610-b45d37c02faa" />

9. What are the top 3 products by purchases?
```
WITH purchased_visits AS
(
SELECT DISTINCT visit_id
FROM events
WHERE event_type = 3
)

SELECT p.page_name, COUNT(*)
FROM events e
JOIN purchased_visits pv 
ON e.visit_id = pv.visit_id
JOIN page_hierarchy p
ON e.page_id = p.page_id
WHERE e.event_type = 2
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;
```
<img width="251" height="112" alt="image" src="https://github.com/user-attachments/assets/12fe2434-2a00-4028-8bef-4a1249c384df" />

10. Using a single SQL query - create a new output table which has the following details:

--How many times was each product viewed?

--How many times was each product added to cart?

--How many times was each product added to a cart but not purchased (abandoned)?

--How many times was each product purchased?
```
DROP TABLE IF EXISTS temp_table;
CREATE TEMP TABLE temp_table AS

WITH product_views AS
(
SELECT p.page_name, COUNT(e.event_type) AS view_count
FROM events e
JOIN event_identifier i
ON e.event_type = i.event_type
JOIN page_hierarchy p
ON e.page_id = p.page_id
WHERE e.event_type = '1'
GROUP BY p.page_name
),
cart AS
(
SELECT p.page_name, COUNT(e.event_type) AS added_to_cart
FROM events e
JOIN event_identifier i
ON e.event_type = i.event_type
JOIN page_hierarchy p
ON e.page_id = p.page_id
WHERE e.event_type = '2'
GROUP BY p.page_name
),
purchases AS
(
SELECT visit_id
FROM events
WHERE event_type = '3'
),
cart_no_purchase AS
(
SELECT p.page_name, COUNT(e.event_type) AS not_purchased
FROM events e
JOIN event_identifier i
ON e.event_type = i.event_type
JOIN page_hierarchy p
ON e.page_id = p.page_id
WHERE e.event_type = '2'
AND e.visit_id NOT IN (SELECT * FROM purchases)
GROUP BY p.page_name
),
purchased_products AS
(
SELECT p.page_name, COUNT(e.event_type) AS purchased
FROM events e
JOIN event_identifier i
ON e.event_type = i.event_type
JOIN page_hierarchy p
ON e.page_id = p.page_id
WHERE e.event_type = '2'
AND e.visit_id IN (SELECT * FROM purchases)
GROUP BY p.page_name
)
SELECT p.product_category, pv.page_name, pv.view_count, c.added_to_cart, cp.not_purchased, pp.purchased
FROM product_views pv
LEFT JOIN cart c
ON pv.page_name = c.page_name
LEFT JOIN cart_no_purchase cp
ON pv.page_name = cp.page_name
LEFT JOIN purchased_products pp
ON pv.page_name = pp.page_name
JOIN page_hierarchy p 
ON pv.page_name = p.page_name
WHERE p.product_category IS NOT NULL;

SELECT *
FROM temp_table;
```
<img width="727" height="264" alt="image" src="https://github.com/user-attachments/assets/4afa69d0-5173-4c57-9bac-9cc4dbbe657e" />

```
DROP TABLE IF EXISTS temp_table2;
CREATE TEMP TABLE temp_table2 AS

SELECT product_category, SUM(view_count) AS view_count, SUM(added_to_cart) AS added_to_cart, SUM(not_purchased) AS not_purchased, SUM(purchased) AS purchased
FROM temp_table
GROUP BY 1;

SELECT * 
FROM temp_table2;
```
<img width="579" height="112" alt="image" src="https://github.com/user-attachments/assets/2f75a97f-3554-4fc1-9cc4-2c4ca80441f2" />


--Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.


--Use your 2 new output tables - answer the following questions:

--Which product had the most views, cart adds and purchases?
```
SELECT *
FROM
(
SELECT 'Most views' AS metric, page_name AS product, view_count
FROM temp_table
ORDER BY 3 DESC
LIMIT 1
) a

UNION ALL

SELECT *
FROM
(
SELECT 'Most cart adds' AS metric, page_name AS product, added_to_cart
FROM temp_table
ORDER BY 3 DESC
LIMIT 1
) b

UNION ALL

SELECT *
FROM
(
SELECT 'Most purchases' AS metric, page_name AS product, purchased
FROM temp_table
ORDER BY 3 DESC
LIMIT 1
) c;
```
<img width="383" height="114" alt="image" src="https://github.com/user-attachments/assets/25123cc0-f1e0-444e-be48-766d535dddca" />

11. Which product was most likely to be abandoned?
```
SELECT page_name AS product, ROUND(not_purchased::NUMERIC * 100 / added_to_cart,2) AS pct_abandoned
FROM temp_table
ORDER BY 2 DESC
LIMIT 1;
```
<img width="300" height="65" alt="image" src="https://github.com/user-attachments/assets/0efac1fb-4227-411e-bc53-f5a6c17622ee" />

12. Which product had the highest view to purchase percentage?
```
SELECT page_name AS product, ROUND(purchased::NUMERIC * 100 / view_count,2) AS pct_purchased
FROM temp_table
ORDER BY 2 DESC
LIMIT 1;
```
<img width="299" height="67" alt="image" src="https://github.com/user-attachments/assets/8f30010c-e07e-445e-81ef-f5b003282b02" />

13. What is the average conversion rate from view to cart add?
```
SELECT ROUND(AVG(added_to_cart::NUMERIC * 100 / view_count),2) AS avg_view_conversion_rate
FROM temp_table;
```
<img width="211" height="60" alt="image" src="https://github.com/user-attachments/assets/6986e6a1-4ab2-49b7-9d23-9c5458f479b1" />

14. What is the average conversion rate from cart add to purchase?
```
SELECT ROUND(AVG(purchased::NUMERIC * 100 / added_to_cart),2) AS cart_add_conversion_rate
FROM temp_table;
```
<img width="209" height="60" alt="image" src="https://github.com/user-attachments/assets/ea6a7d44-d44b-485f-a77c-2b26d9a4a001" />

15. Generate a table that has 1 single row for every unique visit_id record and has the following columns: 
--user_id

--visit_id

--visit_start_time: the earliest event_time for each visit

--page_views: count of page views for each visit

--cart_adds: count of product cart add events for each visit

--purchase: 1/0 flag if a purchase event exists for each visit

--campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date

--impression: count of ad impressions for each visit

--click: count of ad clicks for each visit

--(Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)


```
CREATE TEMP TABLE temp_table3 AS

WITH visits AS 
( 
SELECT visit_id, MIN(event_time) AS visit_start_time 
FROM events 
GROUP BY 1 
)

SELECT u.user_id, e.visit_id, visit_start_time,
COUNT(CASE WHEN e.event_type = '1' THEN e.visit_id END) AS page_views,
COUNT(CASE WHEN e.event_type = '2' THEN e.visit_id END) AS cart_adds,
MAX(CASE WHEN e.event_type = '3' THEN 1 ELSE 0 END) AS purchase, campaign_name,
COUNT(CASE WHEN e.event_type = '4' THEN e.visit_id END) AS impression,
COUNT(CASE WHEN e.event_type = '5' THEN e.visit_id END) AS click,
STRING_AGG(CASE
        	WHEN e.event_type = '2' THEN ph.page_name
   			END,
    		', '
    		ORDER BY e.sequence_number
) AS cart_products
FROM events e
JOIN users u
ON e.cookie_id = u.cookie_id
JOIN visits v
ON e.visit_id = v.visit_id
LEFT JOIN page_hierarchy ph
ON e.page_id = ph.page_id
LEFT JOIN campaign_identifier ci
ON v.visit_start_time BETWEEN ci.start_date AND ci.end_date
GROUP BY 1, 2, 3, ci.campaign_name;

SELECT * 
FROM temp_table3;
```
16. Some ideas you might want to investigate further include:

--Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event
```
SELECT campaign_name, 
SUM(CASE WHEN impression = '1' THEN cart_adds ELSE 0 END) AS impression_cart_adds, 
SUM(CASE WHEN impression = '0' THEN cart_adds ELSE 0 END) AS non_impression_cart_adds,
SUM(CASE WHEN impression = '1' THEN page_views ELSE 0 END) AS impression_page_views,
SUM(CASE WHEN impression = '0' THEN page_views ELSE 0 END) AS non_impression_page_views,
SUM(CASE WHEN impression = '1' THEN purchase ELSE 0 END) AS impression_purchases,
SUM(CASE WHEN impression = '0' THEN purchase ELSE 0 END) AS non_impression_purchases
FROM temp_table3
GROUP BY campaign_name;
```
<img width="1212" height="137" alt="image" src="https://github.com/user-attachments/assets/c0b03bf4-6243-4ac4-b7c7-0c7cf1a6fe9f" />

17. Does clicking on an impression lead to higher purchase rates?
```
SELECT * 
FROM temp_table3;

SELECT ROUND(COUNT(CASE WHEN impression = '1' AND purchase = '1' THEN 1 END)::NUMERIC * 100/ COUNT(CASE WHEN impression = '1' THEN 1 END),2) AS impression_purchase_rates,
ROUND(COUNT(CASE WHEN impression = '0' AND purchase = '1' THEN 1 END)::NUMERIC * 100/ COUNT(CASE WHEN impression = '0' THEN 1 END),2) AS non_impression_rates
FROM temp_table3;
```
<img width="370" height="70" alt="image" src="https://github.com/user-attachments/assets/84751295-30c2-4d51-9eb1-59470795c55c" />

18. What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?
```
SELECT ROUND(COUNT(CASE WHEN impression = '1' AND purchase = '1' AND click = '1' THEN 1 END)::NUMERIC * 100/ COUNT(CASE WHEN impression = '1' AND click = '1' THEN 1 END),2) AS click_purchase_rate,
ROUND(COUNT(CASE WHEN impression = '0' AND purchase = '1' THEN 1 END)::NUMERIC * 100/ COUNT(CASE WHEN impression = '0' THEN 1 END),2) AS non_impression_rates,
ROUND(COUNT(CASE WHEN impression = '1' AND purchase = '1' AND click = '0' THEN 1 END)::NUMERIC * 100/ COUNT(CASE WHEN impression = '1' AND click = '0' THEN 1 END),2) AS impression_no_click_rates
FROM temp_table3;
```
<img width="493" height="57" alt="image" src="https://github.com/user-attachments/assets/e3b21a4a-d2f9-47a7-b483-4ea988213329" />

