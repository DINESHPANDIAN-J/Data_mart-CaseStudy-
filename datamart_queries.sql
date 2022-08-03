
use case1;
-- --Selecting first 10 records from table weekly sales--
select * from weekly_sales limit 10;
 -- <<<<<<<<<<Data Cleansing>>>>>>>>
 -- <<creating new table>> -- 
 -- New table should be with following operations--  
--  (1)Add a week_number as the second column for each week_date value,
--  for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2, etc.-- 
-- (2) Add a month_number with the calendar month for each week_date value as the 3rd column-- 
-- (3)Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values-- 

CREATE TABLE clean_weekly_sales AS
SELECT
  week_date,
  -- --week,month,year functions gives thier respective number from the date ("yyyy-mm-dd")--  
  week(week_date) AS week_number,
  month(week_date) AS month_number,
  year(week_date) AS calendar_year,
  region,
  platform,
  -- when platform is null turning to unknown and keep it in the same column-- 
  CASE
    WHEN segment = 'null' THEN 'Unknown'
    ELSE segment
    END AS segment,
    -- (4)Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
    -- Mapping with given condition and form  new field 
  CASE
    WHEN right(segment, 1) = '1' THEN 'Young Adults'
    WHEN right(segment, 1) = '2' THEN 'Middle Aged'
    WHEN right(segment, 1) IN ('3', '4') THEN 'Retirees'
    ELSE 'Unknown'
    END AS age_band,
    -- (5) Add a new demographic column using the following mapping for the first letter in the segment values: 
  CASE
    WHEN left(segment, 1) = 'C' THEN 'Couples'
    WHEN left(segment, 1) = 'F' THEN 'Families'
    ELSE 'Unknown'
    END AS demographic,
  customer_type,
  transactions,
   -- Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
  sales,
  ROUND(
      sales / transactions,
      2
   ) AS avg_transaction
FROM weekly_sales;
 --  selecting 10 records from clean_weekly_sales -- 
select * from clean_weekly_sales limit 10;

-- << Data Exploration>>-- 

## 1.Which week numbers are missing from the dataset?
 -- creating table with sequence of numbers by auto increment-- 
create table seq100
(x int not null auto_increment primary key);
-- assaigning space for values
insert into seq100 values (),(),(),(),(),(),(),(),(),();
insert into seq100 values (),(),(),(),(),(),(),(),(),();
insert into seq100 values (),(),(),(),(),(),(),(),(),();
insert into seq100 values (),(),(),(),(),(),(),(),(),();
insert into seq100 values (),(),(),(),(),(),(),(),(),();
select * from seq100;
-- 50 sequentials values have been created now adding 50 on each to get 100 records--  
insert into seq100 select x + 50 from seq100;
select * from seq100;
-- limiting the numbers to 52 equals to the no of weeks in a year. 
-- creating new table with 52 numbers 
create table seq52 as (select x from seq100 limit 52);
select distinct x as week_day from seq52 where x not in(select distinct week_number from clean_weekly_sales); 
-- selecting unique values from 52 numbers ,those numbers that should not be in week_number column
select distinct week_number from clean_weekly_sales;

## 2.How many total transactions were there for each year in the dataset?
SELECT
  calendar_year,
  SUM(transactions) AS total_transactions
FROM clean_weekly_sales group by calendar_year;
-- over the tears total has increades from the year 2018--  

## 3.What are the total sales for each region for each month?

SELECT
  month_number,
  region,
  SUM(sales) AS total_sales
FROM clean_weekly_sales
GROUP BY month_number, region
ORDER BY month_number, region;

## 4.What is the total count of transactions for each platform
-- no of transaction takesplace in the diff platforms 
SELECT
  platform,
  count(transactions) AS no_of_transactions
FROM clean_weekly_sales
GROUP BY platform;

## 5.What is the percentage of sales for Retail vs Shopify for each month?
-- using common table expression , for more than one subclass es 
WITH cte_monthly_platform_sales AS (
  SELECT
    month_number,calendar_year,
    platform,
    SUM(sales) AS monthly_sales
  FROM clean_weekly_sales
  GROUP BY month_number,calendar_year, platform
)
SELECT
  month_number,calendar_year,
  ROUND(
    100 * MAX(CASE WHEN platform = 'Retail' THEN monthly_sales ELSE NULL END) /
      SUM(monthly_sales),
    2
  ) AS retail_percentage,
  -- whenever platform is Retail monthly sales do sum of all sales values up to it
  -- we want the cumulative of all so we do max function
  ROUND(
    100 * MAX(CASE WHEN platform = 'Shopify' THEN monthly_sales ELSE NULL END) /
      SUM(monthly_sales),
    2
  ) AS shopify_percentage
FROM cte_monthly_platform_sales
GROUP BY month_number,calendar_year
ORDER BY month_number,calendar_year;
-- retail ahopping is dominant over the shopify

## 6.What is the percentage of sales by demographic for each year in the dataset?

SELECT
  calendar_year,
  demographic,
  SUM(SALES) AS yearly_sales,
  ROUND(
    (
      100 * SUM(sales)/
        SUM(SUM(SALES)) OVER (PARTITION BY demographic)
    ),
    2
  ) AS percentage
FROM clean_weekly_sales
GROUP BY
  calendar_year,
  demographic
ORDER BY
  calendar_year,
  demographic;
  -- couples had contribute more sales in the year 2020--  
  
## 7.Which age_band and demographic values contribute the most to Retail sales?

SELECT
  age_band,
  demographic,
  SUM(sales) AS total_sales
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY age_band, demographic
ORDER BY total_sales DESC;
-- apart from unknown " families with retirees" contribute more towords the retail sales-- 


