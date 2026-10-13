1. In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

--Convert the week_date to a DATE format

--Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc

--Add a month_number with the calendar month for each week_date value as the 3rd column

--Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values

--Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
--segment	age_band
--1	Young Adults
--2	Middle Aged
--3 or 4	Retirees
--Add a new demographic column using the following mapping for the first letter in the segment values:
--segment	demographic
--C	Couples
--F	Families
--Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
--Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
```
DROP TABLE IF EXISTS weekly_sales2;
CREATE TABLE weekly_sales2 AS
SELECT *, TO_DATE(week_date, 'DD/MM/YY') as date, EXTRACT(WEEK FROM TO_DATE(week_date, 'DD/MM/YY')) AS week, 
EXTRACT(MONTH FROM TO_DATE(week_date, 'DD/MM/YY')) AS month, EXTRACT(YEAR FROM TO_DATE(week_date, 'DD/MM/YY')) AS year,
CASE WHEN segment LIKE '%1' THEN 'Young Adults' WHEN segment LIKE '%2' THEN 'Middle Aged' WHEN segment LIKE '%3' OR segment LIKE '%4' THEN 'Retirees' ELSE 'unknown' END AS age_band,
CASE WHEN segment LIKE 'C%' THEN 'Couples' WHEN segment LIKE 'F%' THEN 'Families' ELSE 'unknown' END AS demographic,
ROUND((sales / transactions),2) AS avg_transaction
FROM weekly_sales;

SELECT * 
FROM weekly_sales2;
```
<img width="240" height="83" alt="image" src="https://github.com/user-attachments/assets/237a59de-f2b8-4126-9197-f329c35ff9e7" />

2. What day of the week is used for each week_date value?
```
SELECT week_date, TO_CHAR(date,'Day') 
FROM weekly_sales2;
```
<img width="261" height="451" alt="image" src="https://github.com/user-attachments/assets/78f76f85-deda-411d-bf45-81432816460c" />

3. What range of week numbers are missing from the dataset?
```
SELECT week_number
FROM generate_series(1, 52) AS week_number
WHERE week_number NOT IN (SELECT DISTINCT week FROM weekly_sales2)
```
<img width="150" height="737" alt="image" src="https://github.com/user-attachments/assets/469c3da8-7471-4a98-82c2-3b3f892676d0" />

4. How many total transactions were there for each year in the dataset?
```
SELECT COUNT(transactions) AS no_of_transactions , year
FROM weekly_sales2
GROUP BY year;
```
<img width="175" height="115" alt="image" src="https://github.com/user-attachments/assets/ad87cd46-f1c9-4078-8a0b-e74a593a9e34" />

5. What is the total sales for each region for each month?
```
SELECT SUM(sales), region, month
FROM weekly_sales2
GROUP BY region, month
ORDER BY region, month;
```
6. What is the total count of transactions for each platform
```
SELECT COUNT(transactions), platform
FROM weekly_sales2
GROUP BY platform;
```
<img width="240" height="83" alt="image" src="https://github.com/user-attachments/assets/4eef14b4-8782-4dd7-8d8d-1749ba9cb271" />

7. What is the percentage of sales for Retail vs Shopify for each month?
```
SELECT month, platform, SUM(sales) AS total_sales, ROUND(100 * SUM(sales) / SUM(SUM(sales)) OVER(PARTITION BY month),2) AS sales_pct
FROM weekly_sales2
GROUP BY month, platform;
```
<img width="427" height="390" alt="image" src="https://github.com/user-attachments/assets/278cbc88-ae69-4477-91f7-c2ebcf4abcee" />

8. What is the percentage of sales by demographic for each year in the dataset?
```
SELECT year, demographic, SUM(sales) AS total_sales, ROUND(100 * SUM(sales) / SUM(SUM(sales)) OVER(PARTITION BY year),2) AS sales_pct
FROM weekly_sales2
GROUP BY year, demographic;
```
<img width="388" height="260" alt="image" src="https://github.com/user-attachments/assets/5a492d3c-2766-4c77-bb7a-fbc1ca33188b" />

9. Which age_band and demographic values contribute the most to Retail sales?
```
SELECT age_band, SUM(sales) AS total_sales
FROM weekly_sales2
WHERE platform = 'Retail'
AND age_band != 'unknown'
GROUP BY age_band
ORDER BY total_sales DESC
LIMIT 1;
```

<img width="218" height="61" alt="image" src="https://github.com/user-attachments/assets/2185456c-613d-494f-901f-1376247810b0" />

```
SELECT demographic, SUM(sales) AS total_sales
FROM weekly_sales2
WHERE platform = 'Retail'
AND demographic != 'unknown'
GROUP BY demographic
ORDER BY total_sales DESC
LIMIT 1;
```
<img width="232" height="55" alt="image" src="https://github.com/user-attachments/assets/76fa30c1-b8f1-4c9d-8dda-1e66033d815f" />

10. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?

```
WITH sales_period AS
(
SELECT week_date, sales, 
CASE 
	WHEN week_date::date >= DATE '2020-06-15' 
	AND week_date::date < DATE '2020-06-15' + INTERVAL '4 weeks' 
	THEN 'After' 
	WHEN week_date::date >= DATE '2020-06-15' - INTERVAL '4 weeks'
	AND week_date::date < DATE '2020-06-15' 
	THEN 'Before'
END AS before_after
FROM weekly_sales2
)

SELECT 
	SUM(CASE
		WHEN before_after = 'Before'
		THEN sales END) AS before_sales,
		
	SUM(CASE 
		WHEN before_after = 'After' 
		THEN sales END) AS after_sales,
		
	SUM(CASE 
		WHEN before_after = 'After' 
		THEN sales END) -
	SUM(CASE
		WHEN before_after = 'Before'
		THEN sales END) AS growth,
		
	ROUND((SUM(CASE 
		WHEN before_after = 'After' 
		THEN sales END) -
	SUM(CASE
		WHEN before_after = 'Before'
		THEN sales END))::NUMERIC / SUM(CASE
		WHEN before_after = 'Before'
		THEN sales END) * 100,2) AS growth_pct
FROM sales_period;
```
<img width="388" height="60" alt="image" src="https://github.com/user-attachments/assets/021ad2e0-50ca-454c-8308-50175bf4e355" />


11. What about the entire 12 weeks before and after?
```
WITH sales_period AS
(
SELECT week_date, sales, 
CASE 
	WHEN week_date::date >= DATE '2020-06-15' 
	AND week_date::date < DATE '2020-06-15' + INTERVAL '12 weeks' 
	THEN 'After' 
	WHEN week_date::date >= DATE '2020-06-15' - INTERVAL '12 weeks'
	AND week_date::date < DATE '2020-06-15' 
	THEN 'Before'
END AS before_after
FROM weekly_sales2
)

SELECT 
	SUM(CASE
		WHEN before_after = 'Before'
		THEN sales END) AS before_sales,
		
	SUM(CASE 
		WHEN before_after = 'After' 
		THEN sales END) AS after_sales,
		
	SUM(CASE 
		WHEN before_after = 'After' 
		THEN sales END) -
	SUM(CASE
		WHEN before_after = 'Before'
		THEN sales END) AS growth,
		
	ROUND((SUM(CASE 
		WHEN before_after = 'After' 
		THEN sales END) -
	SUM(CASE
		WHEN before_after = 'Before'
		THEN sales END))::NUMERIC / SUM(CASE
		WHEN before_after = 'Before'
		THEN sales END) * 100,2) AS growth_pct
FROM sales_period;
```
<img width="398" height="61" alt="image" src="https://github.com/user-attachments/assets/2482ed31-02e8-4615-bcfa-ba1822e78fc8" />

12. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
```
SELECT week
FROM weekly_sales2
WHERE date = '2020-06-15';

WITH four_period AS
(
SELECT sales, year,
	CASE
		WHEN week BETWEEN 21 AND 24
		THEN 'Before'
		WHEN week BETWEEN 25 AND 28
		THEN 'After'
		END AS before_after
FROM weekly_sales2
)
SELECT year,
	SUM(CASE WHEN before_after = 'Before' THEN sales END) AS before_sales,
	SUM(CASE WHEN before_after = 'After' THEN sales END) after_sales,	
	SUM(CASE WHEN before_after = 'After' THEN sales END) - SUM(CASE WHEN before_after = 'Before' THEN sales END) AS growth,
	ROUND((SUM(CASE WHEN before_after = 'After' THEN sales END) - SUM(CASE WHEN before_after = 'Before' THEN sales END))::NUMERIC 
	/ SUM(CASE WHEN before_after = 'Before' THEN sales END) * 100,2) AS growth_pct
FROM four_period
GROUP BY year
ORDER BY year;
```
<img width="466" height="114" alt="image" src="https://github.com/user-attachments/assets/20c6971e-3f09-4b23-a91a-cbd8cf2fbc5d" />

---------------
```
WITH twelve_period AS
(
SELECT sales, year,
	CASE
		WHEN week BETWEEN 13 AND 24
		THEN 'Before'
		WHEN week BETWEEN 25 AND 36
		THEN 'After'
		END AS before_after
FROM weekly_sales2
)
SELECT year,
	SUM(CASE WHEN before_after = 'Before' THEN sales END) AS before_sales,
	SUM(CASE WHEN before_after = 'After' THEN sales END) after_sales,	
	SUM(CASE WHEN before_after = 'After' THEN sales END) - SUM(CASE WHEN before_after = 'Before' THEN sales END) AS growth,
	ROUND((SUM(CASE WHEN before_after = 'After' THEN sales END) - SUM(CASE WHEN before_after = 'Before' THEN sales END))::NUMERIC 
	/ SUM(CASE WHEN before_after = 'Before' THEN sales END) * 100,2) AS growth_pct
FROM twelve_period
GROUP BY year
ORDER BY year;
```
<img width="475" height="108" alt="image" src="https://github.com/user-attachments/assets/250bebe2-8580-4383-acd8-49dcf8be2761" />
