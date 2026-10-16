1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month

```
ALTER TABLE interest_metrics
ALTER COLUMN month_year TYPE DATE
USING TO_DATE(month_year, 'MM-YYYY');
```

2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?

```
SELECT month_year, COUNT(*)
FROM interest_metrics 
GROUP BY month_year
ORDER BY month_year ASC NULLS FIRST;
```
<img width="199" height="418" alt="image" src="https://github.com/user-attachments/assets/565bb57b-d20a-487c-acbb-4638e6fb501e" />

3. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?

```
SELECT DISTINCT e.interest_id, a.id 
FROM interest_metrics e
LEFT JOIN interest_map a 
ON e.interest_id::INT = a.id
WHERE a.id IS NULL;
```
<img width="253" height="66" alt="image" src="https://github.com/user-attachments/assets/a3c56013-fa1f-48ea-b898-8833d728cab2" />

```
SELECT DISTINCT a.id
FROM interest_map a
LEFT JOIN interest_metrics e
ON a.id = e.interest_id::INT
WHERE e.interest_id IS NULL;
```
<img width="109" height="215" alt="image" src="https://github.com/user-attachments/assets/de2be645-9caa-4a39-916d-51b6b22fe3f3" />

4. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.

```
SELECT e.*, a.interest_name, a.interest_summary, a.created_at, a.last_modified
FROM interest_metrics e
LEFT JOIN interest_map a 
ON e.interest_id::INT = a.id
WHERE e.interest_id = '21246';
```

5. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?

```
SELECT e.*, a.interest_name, a.interest_summary, a.created_at, a.last_modified
FROM interest_metrics e
LEFT JOIN interest_map a 
ON e.interest_id::INT = a.id
WHERE e.month_year < a.created_at::DATE;
```
<img width="1672" height="459" alt="image" src="https://github.com/user-attachments/assets/f57b150d-55d8-4b8d-94f5-582327e998a1" />

6. Which interests have been present in all month_year dates in our dataset?

```
SELECT COUNT(DISTINCT month_year), interest_id, interest_name
FROM interest_metrics e
JOIN interest_map a
ON e.interest_id::INT = a.id
GROUP BY interest_id, interest_name
HAVING COUNT(DISTINCT month_year) = (SELECT COUNT(DISTINCT month_year) FROM interest_metrics);
```
<img width="556" height="456" alt="image" src="https://github.com/user-attachments/assets/74a113bf-5730-40e2-a071-d7e45e18cf7f" />

7. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?

```
WITH CTE AS
(
SELECT COUNT(DISTINCT month_year) AS total_months , interest_id
FROM interest_metrics e
JOIN interest_map a
ON e.interest_id::INT = a.id
GROUP BY interest_id
),
CTE2 AS
(
SELECT total_months, COUNT(interest_id) AS interests
FROM CTE
GROUP BY total_months
),
CTE3 AS
(
SELECT total_months, interests, SUM(interests) OVER (ORDER BY total_months DESC) AS cumulative_sum
FROM CTE2
)
SELECT total_months, cumulative_sum, ROUND(cumulative_sum * 100 / (SELECT SUM(interests) FROM CTE2),2) AS cumulative_pct
FROM CTE3
WHERE cumulative_sum * 100 / (SELECT SUM(interests) FROM CTE2) >= 90
GROUP BY total_months, cumulative_sum
ORDER BY total_months DESC;
```
<img width="374" height="187" alt="image" src="https://github.com/user-attachments/assets/124ee5dc-8772-4f88-8429-e4e388f4f8b9" />

8. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?

```
WITH CTE AS
(
SELECT interest_id, COUNT(DISTINCT month_year) AS total_months
FROM interest_metrics
GROUP BY interest_id
),
id_to_keep AS
(
SELECT interest_id
FROM CTE
WHERE total_months >= 6
)
SELECT COUNT(*) 
FROM interest_metrics
WHERE interest_id NOT IN (SELECT interest_id FROM id_to_keep);
```
<img width="106" height="63" alt="image" src="https://github.com/user-attachments/assets/2a4488be-cf3b-4d72-bab3-48b3d654eddd" />

--Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.


9. After removing these interests - how many unique interests are there for each month?

```
WITH CTE AS
(
SELECT interest_id, COUNT(DISTINCT month_year) AS total_months
FROM interest_metrics
GROUP BY interest_id
),
id_to_keep AS
(
SELECT interest_id
FROM CTE
WHERE total_months >= 6
)	

SELECT month_year, COUNT(DISTINCT interest_id)
FROM interest_metrics
WHERE interest_id IN (SELECT interest_id FROM id_to_keep)
GROUP BY 1;
```
<img width="200" height="417" alt="image" src="https://github.com/user-attachments/assets/8c949b15-05aa-49b9-ac43-16963a97012f" />

10. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year

```
WITH CTE AS
(
SELECT interest_id, COUNT(DISTINCT month_year) AS total_months
FROM interest_metrics
GROUP BY interest_id
),
id_to_keep AS
(
SELECT interest_id
FROM CTE
WHERE total_months >= 6
),
rankings AS
(
SELECT interest_id, month_year, composition, ROW_NUMBER() OVER(PARTITION BY interest_id ORDER BY composition DESC) AS rn
FROM interest_metrics
WHERE interest_id IN (SELECT interest_id FROM id_to_keep)
),
top_ten AS
(
SELECT interest_id, month_year, composition
FROM rankings
WHERE rn = 1
ORDER BY composition DESC
LIMIT 10
),
bottom_ten AS
(
SELECT interest_id, month_year, composition
FROM rankings
WHERE rn = 1
ORDER BY composition ASC
LIMIT 10
)
SELECT *, 'Top Ten' AS position
FROM top_ten

UNION ALL

SELECT *, 'Bottom Ten' AS position
FROM bottom_ten
ORDER BY composition DESC;
```
<img width="502" height="537" alt="image" src="https://github.com/user-attachments/assets/7028cf89-32b2-488f-bed0-d94ba637c8c8" />

11. Which 5 interests had the lowest average ranking value?

```
SELECT interest_id, AVG(ranking) AS avg_ranking
FROM interest_metrics
GROUP BY interest_id
ORDER BY avg_ranking ASC
LIMIT 5;
```
<img width="346" height="164" alt="image" src="https://github.com/user-attachments/assets/77f00e1b-0712-4cd7-aa0b-dbfeaf740c68" />

12. Which 5 interests had the largest standard deviation in their percentile_ranking value?

```
SELECT interest_id, STDDEV_POP(percentile_ranking) AS std_dev
FROM interest_metrics
WHERE interest_id IS NOT NULL
GROUP BY interest_id 
ORDER BY std_dev DESC
LIMIT 5;
```
<img width="318" height="168" alt="image" src="https://github.com/user-attachments/assets/1c074e18-80e5-4b5c-9e32-99ae0b956bd9" />

13. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?

```
WITH ranked AS
(
SELECT interest_id, month_year, percentile_ranking, ROW_NUMBER() OVER(PARTITION BY interest_id ORDER BY percentile_ranking DESC) AS max_value, 
ROW_NUMBER() OVER(PARTITION BY interest_id ORDER BY percentile_ranking ASC) AS min_value
FROM interest_metrics
WHERE interest_id::INT IN (6260,23,131,150,38992)
)
SELECT interest_id, month_year, percentile_ranking
FROM ranked
WHERE max_value = 1 
OR min_value = 1;
```
<img width="403" height="286" alt="image" src="https://github.com/user-attachments/assets/8e91a1a0-820b-4ad5-8bc7-75c149db111d" />
