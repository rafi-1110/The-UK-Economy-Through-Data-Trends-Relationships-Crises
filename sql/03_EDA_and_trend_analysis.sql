--- Exploratory data analysis & trend analysis.
--- The following will be divided into two part; the first involves at simply inspecting the data, 
-- and the second about performing some trend analysis and answering the questions below. 
--- "How have inflation, GDP, unemployment and wages changed over time? What might have been the reason for this?"

-- Part 1: Getting to know the data.

SELECT * 
FROM dim_date
LIMIT 10;

SELECT *
FROM dim_date
ORDER BY full_date ASC
LIMIT 3;
-- Result: The earlierst data point is from the 1st of Jan 1997.

SELECT full_date
FROM dim_date
ORDER BY full_date DESC
LIMIT 3;
-- Result: The latest data point is from the 1st April 2026.

SELECT COUNT(*) AS total_data_points
FROM dim_date;
-- Shows that there are 352 rows/data points.

SELECT COUNT(*)
FROM dim_date
WHERE is_post_covid = TRUE;
-- Result: 74 out of the 352 data points are post covid which will be useful to know.

SELECT COUNT(*)
FROM dim_date
WHERE full_date BETWEEN '2020-01-30' AND '2021-07-19';
-- Result: The WHO declared the outbreak to be a public health emergency on 30/01/2020 and on 21/07/2021 the UK lifted most of its strict rule. 
-- There are 18 points of data within the health emergency perdiod.

SELECT *
FROM inflation
LIMIT 10;

SELECT full_date,
	   cpih_index
FROM inflation
ORDER BY cpih_index DESC;
-- Result: The CPIH index value represents the price level relative to 2015 (=100), not a percentage change itself. 
-- A value of 141.8 means prices were 41.8% higher on 01/04/26 than April 2015, the highest range from 2015.

SELECT ROUND(MIN(cpih_annual_rate),3) AS minimum_cpih_annual_rate,
	   ROUND(MAX(cpih_annual_rate),3) AS maximum_cpih_annual_rate,
	   ROUND(AVG(cpih_annual_rate),3) AS average_cpih_annual_rate,
	   ROUND(MIN(cpih_monthly_rate),3) AS minimum_cpih_monthly_rate,
	   ROUND(MAX(cpih_monthly_rate),3) AS maximum_cpih_monthly_rate,
	   ROUND(AVG(cpih_monthly_rate),3) AS average_cpih_monthly_rate
FROM inflation;
-- Result: The minimum, maxmimum and average for the CPIH annual rate are 0.2%, 9.6% and 2.47%. 
-- For the same monthly rate, these statistics are -0.7%, 2.1% and 0.21%.

SELECT *
FROM monthly_bank_rate
LIMIT 10;

SELECT MIN(rate) AS minimum_monthly_rate,
	   MAX(rate) AS maximum_monthly_rate,
	   ROUND(AVG(rate),3) AS average_monthly_rate
FROM monthly_bank_rate;
-- Result: The minimum, maximum and average rate throughout the period are 0.1%, 7.5% and 2.89% respectively.

SELECT *
FROM monthly_unemployment
LIMIT 10;

SELECT full_date AS date,
	   unemployment_rate
FROM monthly_unemployment
ORDER BY unemployment_rate DESC;
-- Result: The highest unemployment rate registered was 8.5% on 01/10/2011.

SELECT full_date AS date,
	   unemployment_rate
FROM monthly_unemployment
ORDER BY unemployment_rate ASC;
-- Result: On the other side, the lowest unemployment rate registered was 3.6% on 01/06/2022.

SELECT *
FROM monthly_gdp
LIMIT 10;

SELECT full_date,
	   gdp_index
FROM monthly_gdp
ORDER BY gdp_index DESC;
-- Result: Similarly to CPIH index, the GDP index value represents the price level relative to a base year, not a percentage. 
-- The base year here is 2019. 
-- Also, the highest index value is 103.4 for the date 01/03/2026.
-- Continued: This implies that on that day the GDP was 3.4% (index - 100) higher than on 2019.

SELECT ROUND(MIN(gdp_growth_yoy),3) AS minimum_gdp_yoy_rate,
	   ROUND(MAX(gdp_growth_yoy),3) AS maximum_gdp_yoy_rate,
	   ROUND(AVG(gdp_growth_yoy),3) AS average_gdp_yoy_rate,
	   ROUND(MIN(gdp_growth_3m_yoy),3) AS minimum_gdp_3m_yoy_rate,
	   ROUND(MAX(gdp_growth_3m_yoy),3) AS maximum_gdp_3m_yoy_rate,
	   ROUND(AVG(gdp_growth_3m_yoy),3) AS average_gdp_3m_yoy_rate
FROM monthly_gdp;
-- Result: It shows that the mininum, maximum and average GDP YOY growth rate are -24.3%, 30% and 1.84% respectively
-- Continued: Similarly, for the same stastics, specifically for the 3 month YOY, the growth rates are -21.3%, 25.9% and 1.83%.


-- Part 2: Simple Trend Analysis - How have inflation, GDP, unemployment and wages changed over time? What might have been the reason for this? [KEY PROJECT QUESTION]

SELECT year,
	   ROUND(AVG(cpih_annual_rate),2) AS average_inflation_by_year
FROM inflation
GROUP BY year
ORDER BY year ASC;
-- Result: The annual average inflation indicates to be increasing over time with the notable peaks which are 2008, 2011 and more recently, in 2022.

SELECT year,
	   ROUND(AVG(gdp_growth_yoy),2) AS average_gdp_growth_by_year
FROM monthly_gdp
GROUP BY year
ORDER BY year ASC;
-- Result: The annual average GDP growth shows ups and down at specific periods. There growth rate falls below 0 in 2009 and 2020. 
-- The trend reverse and has the highest peak in 2021.

SELECT year,
	   ROUND(AVG(unemployment_rate),2) AS average_unemployment_by_year
FROM monthly_unemployment
GROUP BY year
ORDER BY year ASC;
-- Result: The general trend shows that the average annual unemployment rate is slowly decreasing from 1997 to around 2008, 
-- but then it has a steady increase till mid 2012 from which it starts to
-- slowly decrease again and then plateu for some years before going back up in 2026.

--- NOTE (IMPORTANT): One of the project questions asks me to describe how wages changed
--- over time alongside the other economic indicators, and what might explain those changes.
--- Obstacles:
--- 1. The ONS wage data available was only yearly, not a monthly growth rate. 
-----  This meant I couldn't generate a "date_id" for it the way I did for the other tables, so it doesn't link directly to dim_date.
--- 2. The data only covers 1949-2015, missing the last 11 years of wage growth.
--- Solution:
--- I downloaded the ONS file and cleaned it directly from the CSV (only two columns: year and growth rate). Removed metadata rows, renamed columns to "year" and "growth_rate", and loaded into PostgreSQL (SEE QUERIES BELOW).
--- Trade-off note: this is a case where real-world data doesn't arrive at the granularity or time range you want, and matching it perfectly with other tables isn't always possible.

CREATE TABLE IF NOT EXISTS wages_annual_growth(
    year INTEGER PRIMARY KEY,
    growth_rate NUMERIC);

SELECT * 
FROM wages_annual_growth;
-- Result: The most noticeable increase occurred in 1975 when the wage growth hit 29.4%.


--- Summary: What were the reason of the changes of the economic indicators in that period?

-- 1. Inflation: Between 1997 to 2007 the inflation rate fluctuated between 1.18% and 2.45% but it rose 3.5% in 2008.
-- The most likely reasons were due to a rapid increase in brent crude oil prices in 2008, which went over $140 per barrel at one point, 
-- but also because the the Pound Sterling lost a lot of value against the Dollar
-- Consequently, this led to more higher costs of imports as it was more expensive to transport goods and also it would take 
-- more pounds to buy goods from abroad, resulting in higher inflation.

-- 2. GDP: There is a noticeable increase in the year 2000. This is due to the dot.com boom when the markets were driven by substancial 
-- investments in tech related stocks due to speculation.
-- We know that this was actually a bubble and a lot of these investements were wiped out as a lot of these start-ups went bankrupt 
-- which is reflected
-- in the data shown here where in 2002 the growth rate fell to 1.54%
-- Additionally, we observe the effects of the 2008 financial crisis, during which GDP growth fell from 2.93% in 2007 to 0.21% in 2008, 
-- before declining further to -4.54% in 2009. 
-- downturn was caused by a chain reaction of events that began in the banking sector and spread throughout the rest of the economy, l
-- eading to widespread economic contraction.
-- In 2020 and 2021, the UK experienced its largest annual fall and rise in GDP growth, at -9.57% and 9.63%, respectively. 
-- The sharp decline in 2020 was caused by the COVID-19 pandemic, while the strong growth in 2021 reflected the post-lockdown economic recovery.
-- However, GDP growth struggled to exceed 1.28% over the following three years, suggesting that the 2021 rebound was largely 
-- a result of post-pandemic recovery rather than sustained economic growth.

-- 3. Unemployment: The most noticeable trend is the high unemployment rate between 2009 and 2013, which peaked at 8.09% in 2011. 
-- This was largely due to the aftermath of the 2008 financial crisis, 
-- combined with post-crisis austerity measures and reduced business confidence, which caused firms to hire fewer workers.

-- 4. Wages: Between 1949 and 1980, wage growth was generally strong, with particularly rapid increases during the 1970s. 
-- Growth peaked at 29.4% in 1975, largely due to rising wage demands driven by skyrocketing oil prices and inflation, 
-- alongside the increased bargaining power of trade unions, which led businesses to raise workers' wages.