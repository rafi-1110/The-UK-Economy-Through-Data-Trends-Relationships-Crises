--- Unemployment and Inflation.
--- The next section will be focusing on answering: "How is unemployment linked to inflation?" 
--- Specifically, we will also deep dive into other questions, such as:
--- 1. Is there a positive or negative relationship between unemployment and inflation? [Philips Curve]
--- 2. Did the relationship change after COVID? if so, by how much?
--- 3. During which years was unemployment highest?
--- 4. What happened during major economic events? For example, between 2008-2011 and 2020-2023?

-- Inspecting both unemployment and inflation data again as separate tables.
SELECT * 
FROM monthly_unemployment;

SELECT *
FROM inflation;

--- 1. Is there a positive or negative relationship between unemployment and inflation? [Phillips Curve]
-- Here we test whether there's a correlation between unemployment and inflation rates.
-- The Phillips Curve is an economic concept proposing an inverse relationship between the two: periods of high unemployment tend to coincide with low inflation, and vice versa.
-- We'll test this hypothesis first without differencing, then with differencing, following the same approach used in the interest-rate-vs-inflation analysis.

-- Joining the tables.
SELECT I.year,
	   I.full_date,
	   I.cpih_monthly_rate,
	   U.unemployment_rate AS unemployment_monthly_rate
FROM inflation AS I
INNER JOIN monthly_unemployment AS U
ON I.date_id = U.date_id;

-- Using window function to compute the correlation between monthly cpih and unmployment rate between 1997 and 2026.
WITH cte_corr_no_diff AS (
SELECT I.year,
	   I.full_date,
	   I.cpih_monthly_rate,
	   U.unemployment_rate AS unemployment_monthly_rate
FROM inflation AS I
INNER JOIN monthly_unemployment AS U
ON I.date_id = U.date_id
)
SELECT ROUND(CORR(cpih_monthly_rate, unemployment_monthly_rate)::numeric, 4) AS corr_no_diff
FROM cte_corr_no_diff;
-- The result shows a value of -0.0994 which suggest a very weak negative correlation.
-- This provides a little evidence that supports the theory of the Philips curve.

-- Computing correlation using differencing to remove any trend.
WITH cte_corr_with_diff AS (
SELECT I.year,
	   I.full_date,
	   I.cpih_monthly_rate - LAG(I.cpih_monthly_rate, 1) OVER(ORDER BY I.full_date) as cpih_monthly_rate_diff,
	   U.unemployment_rate - LAG(U.unemployment_rate, 1) OVER(ORDER BY I.full_date) AS unemployment_monthly_rate_diff
FROM inflation AS I
INNER JOIN monthly_unemployment AS U
ON I.date_id = U.date_id
)
SELECT ROUND(CORR(cpih_monthly_rate_diff, unemployment_monthly_rate_diff)::numeric, 4) AS correlation_diff
FROM cte_corr_with_diff;
-- Now the result is -0.0371 which is a near-zero correlation. Here removing the trend actually undercuts that evidence rather than reinforcing it.
-- So, the conclusion is the following: correlation is weak (-0.0994 no lag, -0.0371 differenced), directionally matching the Phillips Curve but too close to zero to call it a strong correlation.
-- Interestingly, differencing weakened it rather than strengthening it.

--- 2. Did the relationship change after COVID? If so, by how much?

-- Pre-COVID
WITH cte_corr_pre_covid AS (
SELECT I.year,
	   I.full_date,
	   I.is_post_covid,
	   I.cpih_monthly_rate - LAG(I.cpih_monthly_rate, 1) OVER(ORDER BY I.full_date) as cpih_monthly_rate_diff,
	   U.unemployment_rate - LAG(U.unemployment_rate, 1) OVER(ORDER BY I.full_date) AS unemployment_monthly_rate_diff
FROM inflation AS I
INNER JOIN monthly_unemployment AS U
ON I.date_id = U.date_id
WHERE I.is_post_covid IS FALSE -- Filtering by is_post_covid column
)
SELECT ROUND(CORR(cpih_monthly_rate_diff, unemployment_monthly_rate_diff)::numeric, 4) AS correlation_pre_covid
FROM cte_corr_pre_covid;
-- The result is -0.0625.

-- Post-COVID
WITH cte_corr_post_covid AS (
SELECT I.year,
	   I.full_date,
	   I.is_post_covid,
	   I.cpih_monthly_rate - LAG(I.cpih_monthly_rate, 1) OVER(ORDER BY I.full_date) as cpih_monthly_rate_diff,
	   U.unemployment_rate - LAG(U.unemployment_rate, 1) OVER(ORDER BY I.full_date) AS unemployment_monthly_rate_diff
FROM inflation AS I
INNER JOIN monthly_unemployment AS U
ON I.date_id = U.date_id
WHERE I.is_post_covid IS TRUE -- Filtering by is_post_covid column
)
SELECT ROUND(CORR(cpih_monthly_rate_diff, unemployment_monthly_rate_diff)::numeric, 4) AS correlation_post_covid
FROM cte_corr_post_covid;
-- The result gives 0.0211.

-- Conclusion: correlation flipped from -0.0625 pre-COVID to +0.0211 post-COVID (a swing of around 0.087), but both are near zero, too weak to read much into, 
-- and the smaller post-COVID sample makes it more noise-prone.
-- Possible reason: COVID triggered unemployment and inflation spikes from a common shock (lockdowns) rather than the usual unemployment-drives-inflation channel the Phillips Curve describes.

--- 3. During which years was unemployment highest?

SELECT full_date,
	   unemployment_rate
FROM monthly_unemployment
ORDER BY unemployment_rate DESC;
-- The highest recorded unemployment rate was on 2011-10-01 with a rate of 8.5%.
-- But what are the years where unemployment was highest?

SELECT year,
	   ROUND(AVG(unemployment_rate),2) AS average_unemployment_by_year
FROM monthly_unemployment
GROUP BY year
ORDER BY average_unemployment_by_year DESC;
-- This shows that the top 3 years with the highest average unemployment rates are 2011, 2012 and 2010 with 8.09%, 7.98% and 7.89% respectively.

--- 4. What happened during major economic events? For example, between 2008-2011 and 2020-2023?
-- Going to use CASE clause to differentiate the different periods.
SELECT
    CASE
        WHEN I.full_date BETWEEN '2008-01-01' AND '2011-12-31' THEN 'Financial Crisis (2008-2011)'
        WHEN I.full_date BETWEEN '2020-01-01' AND '2023-12-31' THEN 'COVID & Aftermath (2020-2023)'
        ELSE 'Other periods'
    END AS economic_period,
    ROUND(AVG(I.cpih_monthly_rate), 4) AS avg_monthly_inflation,
    ROUND(AVG(U.unemployment_rate), 4) AS avg_monthly_unemployment,
    MIN(U.unemployment_rate) AS min_unemployment,
    MAX(U.unemployment_rate) AS max_unemployment
FROM inflation AS I
INNER JOIN monthly_unemployment AS U
ON I.date_id = U.date_id
GROUP BY economic_period
ORDER BY economic_period;
-- The result show that the average the Financial Crisis had the highest average unemployment (7.32%) and lowest inflation (0.24%).
-- While COVID & Aftermath had the lowest average unemployment (4.25%) and highest inflation (0.39%).
-- The "Other periods" bucket sits before the Financial Crisis and also in between on both measures.