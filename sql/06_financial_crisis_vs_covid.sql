--- 2008 Financial Crisis vs COVID-19
--- The next section will focus on answering: "How did the 2008 Financial Crisis and COVID-19 compare in their impact on the economy?"

--- Specifically, we will look at the following questions:
--- 1. How did GDP, unemployment, inflation and wages behave in the 5 years before the 2008 Financial Crisis and during the following 5-year recovery period? How did these same metrics behave during and after COVID-19? 
--- 2. Which crisis had a bigger impact, and which one did the economy recover from faster?
--- 3. Are there any patterns that repeat across both crises, or was each crisis different? Are there any interesting events or statistics?

-- Inspecting the GDP, unemployment, inflation and wages tables again for this comparison.

-- Visualising the wages table.
SELECT *
FROM wages_annual_growth;

-- During the COVID & Post-Pandemic period, GDP growth fluctuates between -8.83% and 7.90%, showing a large change during the period. 
-- Unemployment fluctuates between 3.78% and 4.60%, while inflation fluctuates between 0.07% and 0.74%. 
-- GDP growth was at its lowest in 2020 at -8.83%, before increasing to 7.90% in 2021. Inflation was also highest in 2022 at 0.74%.

-- Joining all the relevant tables together with the small "wage" caveat.
SELECT
    D.year,
    G.gdp_growth_3m_yoy,
    U.unemployment_rate as monthly_unemployment_rate,
    I.cpih_monthly_rate,
    w.growth_rate AS wage_growth
FROM monthly_gdp G
JOIN dim_date D ON G.date_id = D.date_id
JOIN monthly_unemployment U ON U.date_id = D.date_id
JOIN inflation I ON I.date_id = D.date_id
LEFT JOIN wages_annual_growth W ON W.year = D.year -- Note: Left join used because Inner join would have left out all the rows where there are no "maatching" wage rows.
WHERE D.year BETWEEN 2002 AND 2025
ORDER BY D.year;

--- 1. How did GDP, unemployment, inflation and wages behave in the 5 years before the 2008 Financial Crisis and during the following 5-year recovery period? 
--- 1. How did these same metrics behave during and after COVID-19?
SELECT
    D.year,
    G.gdp_growth_3m_yoy,
    U.unemployment_rate AS monthly_unemployment_rate,
    I.cpih_monthly_rate,
    W.growth_rate AS wage_growth,
    CASE
        WHEN D.year BETWEEN 2002 AND 2007 THEN '2002-2007 Period'
        WHEN D.year BETWEEN 2008 AND 2013 THEN 'Financial Crisis Period'
        WHEN D.year BETWEEN 2020 AND 2025 THEN 'Covid & Post Pandemic Period'
    END AS economic_period
FROM monthly_gdp G
JOIN dim_date D ON G.date_id = D.date_id
JOIN monthly_unemployment U ON U.date_id = D.date_id
JOIN inflation I ON I.date_id = D.date_id
LEFT JOIN wages_annual_growth W ON W.year = D.year -- Note: Left join used because inner join would drop all rows with no matching wage row.
WHERE D.year BETWEEN 2002 AND 2025
ORDER BY D.year;

-- Using window function and group by to summarise these.
WITH cte_economic_period1 AS (
SELECT
    D.year,
    G.gdp_growth_3m_yoy,
    U.unemployment_rate AS monthly_unemployment_rate,
    I.cpih_monthly_rate,
    W.growth_rate AS wage_growth,
    CASE
        WHEN D.year BETWEEN 2003 AND 2007 THEN '5 Years Pre-Crisis' -- 5  years before the financial crisis.
        WHEN D.year BETWEEN 2008 AND 2012 THEN 'Financial Crisis & Recovery' -- 2008 Financial Crisis year plus the following 4 years.
        WHEN D.year BETWEEN 2020 AND 2024 THEN 'Covid & Post-Pandemic' -- Pandemic year and post pandemic.
    END AS economic_period
FROM monthly_gdp G
JOIN dim_date D ON G.date_id = D.date_id
JOIN monthly_unemployment U ON U.date_id = D.date_id
JOIN inflation I ON I.date_id = D.date_id
LEFT JOIN wages_annual_growth W ON W.year = D.year 
WHERE (D.year BETWEEN 2003 AND 2012) OR (D.year BETWEEN 2020 AND 2024)
)
SELECT year,
       economic_period,
       ROUND(AVG(gdp_growth_3m_yoy), 4) AS average_gdp_growth,
       ROUND(AVG(monthly_unemployment_rate), 4) AS average_unemployment_rate,
       ROUND(AVG(cpih_monthly_rate), 4) AS average_inflation_rate,
	   ROUND(AVG(wage_growth), 4) AS average_wage_growth
FROM cte_economic_period1
GROUP BY year, economic_period
ORDER BY year ASC;
-- During the COVID & Post-Pandemic period, GDP growth fluctuated between -8.83% and 7.90%, showing a much larger swing than during the Financial Crisis & Recovery period. 
-- Unemployment fluctuated between 3.78% and 4.60%, remaining relatively low throughout the period. 
-- Inflation fluctuated between 0.07% and 0.74%, with inflation rising sharply after the initial pandemic shock and reaching its highest level in 2022.
-- We only have wages inflation up until 2012 for this analysis (the whole dataset if from 1997 to 2015). This means no Covid & Post-Pandemic Analysis.
-- What we can see here is that 5 years before the crisis the wages would grow betwen 3.5% and 5.9% per year. But after 2008 this would drop to 0.2% in 2009 and stay below 2% between 2010 and 2012.

--- 2. Which crisis had a bigger impact, and which one did the economy recover from faster?
-- Based on the data, COVID had a bigger impact on GDP, asthe annual average GDP growth fell to -8.83%, compared to -4.78% during the Financial Crisis. 
-- However, the Financial Crisis had a bigger impact on unemployment, with the annual average reaching 8.09%, compared to 4.60% during COVID.
-- In terms of recovery, COVID appears to have had a faster recovery. GDP growth went from -8.83% in 2020 to 7.90% in 2021. 
-- In comparison, after the Financial Crisis, GDP growth remained relatively weak for several years.

--- 3. Are there any patterns that repeat across both crises, or was each crisis different? Are there any interesting events or statistics?
-- There are some patterns that are similar across both crises. GDP growth fell during both periods, followed by a recovery in the years after. 
-- However, the impact on unemployment and inflation was different.
-- Overall, both crises caused a fall in GDP growth, but the impact on the economy was different. 
-- The Financial Crisis mainly affected unemployment, while COVID had a larger impact on GDP growth and was followed by higher inflation.
-- Also, it is worth noting that the high GDP growth rates in 2021 and 2022 were most likely due to lockdown restrictions being lifted and the economy recovering from COVID-19.
-- However, we can see GDP growth falling again in 2023 and 2024. This could be due to two main reasons:
-- 1. GDP fell significantly during the lockdown, so the strong growth in 2021 and 2022 was partly due to the economy recovering from this fall. Once the economy had recovered, the unusually high growth rates were no longer expected.
-- 2. The war in Ukraine may have also contributed to slower GDP growth by affecting energy prices, inflation and the wider global economy.