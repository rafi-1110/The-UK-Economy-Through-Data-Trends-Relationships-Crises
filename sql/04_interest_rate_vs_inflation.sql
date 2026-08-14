--- Interest rate and Inflation.
--- The following will be focusing on answering the question: "Is there a lag between interest rates and inflation?" 
--- There will the opportunity to to deep dive into more meaningful questions such as "Did rates increase before or after inflation?" or "How strong is the relationship?"

-- Inspecting the source tables to understand their structure and contents.
SELECT *
FROM inflation
LIMIT 10;

SELECT *
FROM monthly_bank_rate
LIMIT 10;

-- Joining the inflation and monthly Bank Rate tables using their shared date identifier.
SELECT I.date_id,
	   I.full_date,
	   B.rate AS bank_rate_monthly,
	   I.cpih_monthly_rate
FROM inflation AS I
INNER JOIN monthly_bank_rate AS B
ON I.date_id = B.date_id
ORDER BY full_date ASC;

-- Now, my hypothesis is that BoE rate and inflation rate have a postive correlation, implying that as inlfation rises, the BoE is likely to increase the base rate to reduce inflation and vice versa.
-- Monetary policy does not affect the economy immediately. Changes in interest rates typically take several months to influence inflation,
-- with many estimates suggesting a transmission lag of around 12 months (or even 18).

-- First, calculating the correlation without applying a lag.
-- This provides a baseline for comparison with the lagged analysis.
WITH CTE_correlation_no_lag AS (
SELECT I.date_id,
	   I.full_date,
	   B.rate AS bank_rate_monthly,
	   I.cpih_monthly_rate
FROM inflation AS I
INNER JOIN monthly_bank_rate AS B
ON I.date_id = B.date_id
ORDER BY full_date ASC
)
SELECT ROUND(CORR(cpih_monthly_rate, bank_rate_monthly)::numeric, 4) AS corr_no_lag_or_differencing -- Note: Used ""::numeric" to cast the float output of CORR() so ROUND() could process it. This is used to transform the FLOAT valus into a NUMERIC as this is what we used
FROM CTE_correlation_no_lag;
-- The result shows a value of -0.0305. The near-zero correlation suggests little linear relationship when comparing both variables in the same month.
--- This supports investigating whether a lagged relationship exists.

-- Correlation with 12 month lag applied.
WITH CTE_with_lag_12 AS (
SELECT I.date_id,
       I.full_date,
       B.rate AS bank_rate_monthly,
       I.cpih_monthly_rate,
       LAG(I.cpih_monthly_rate, 12) OVER (ORDER BY I.full_date) AS cpih_12mo_lag  -- Applying the 12 month lag here
FROM inflation AS I
INNER JOIN monthly_bank_rate AS B
ON I.date_id = B.date_id
ORDER BY I.full_date ASC
)
SELECT ROUND(CORR(cpih_12mo_lag, bank_rate_monthly)::numeric, 4) AS corr_12_mo_lag
FROM CTE_with_lag_12;
-- The result here shows a value of +0.0603, still a weak correlation.
-- The sign flips from negative to positive compared to the no-lag version, which is directionally consistent with the hypothesis.
-- However, the actual size of the change is small, since both values are close to zero.
-- Also, the relationship may still be influenced by long-term trends rather than a genuine causal effect.
-- Solution:
-- To investigate this further, apply differencing. Differencing subtracts each observation from its previous value.
-- This removes long-term trends and makes the series more stationary, allowing the analysis to focus on month-to-month changes rather than overall trends.


-- Differenced version with no lag correlation:
WITH cte_diff_no_lag AS (
SELECT I.date_id,
       I.full_date,
       B.rate - LAG(B.rate, 1) OVER (ORDER BY I.full_date) AS rate_diff, -- Applying bank rate differencing
       I.cpih_monthly_rate - LAG(I.cpih_monthly_rate, 1) OVER (ORDER BY I.full_date) AS cpih_diff -- Applying inflation differencing to account for the monetary policy implementation
FROM inflation AS I
INNER JOIN monthly_bank_rate AS B
ON I.date_id = B.date_id
)
SELECT ROUND(CORR(cpih_diff, rate_diff)::numeric, 4) AS correlation_diff
FROM cte_diff_no_lag;
-- The differenced correlation is +0.0396, indicating a very weak positive linear relationship.
-- Compared with the raw, no-lag correlation (-0.0305), differencing flips the sign from negative to positive.
-- This suggests the raw correlation may have been partly driven by shared long-term trends rather than a real month-to-month link.


-- Differenced version with 12 month lag correlation:
WITH cte_diff_12_mo_lag AS (
SELECT I.date_id,
       I.full_date,
       B.rate - LAG(B.rate, 1) OVER (ORDER BY I.full_date) AS rate_diff,
       I.cpih_monthly_rate - LAG(I.cpih_monthly_rate, 1) OVER (ORDER BY I.full_date) AS cpih_diff
FROM inflation AS I
INNER JOIN monthly_bank_rate AS B
ON I.date_id = B.date_id
),
cte_diff_lag AS (
SELECT full_date,
       rate_diff,
       LAG(cpih_diff, 12) OVER (ORDER BY full_date) AS cpih_diff_12mo_lag -- A 12 month lag is then applied to the differenced inflation series to account for the delayed implementation of monetary policy
FROM cte_diff_12_mo_lag
)
SELECT ROUND(CORR(cpih_diff_12mo_lag, rate_diff)::numeric, 4) AS correlation_diff_lag12
FROM cte_diff_lag;
-- The differenced 12-month lag correlation is +0.0324, indicating a very weak positive linear relationship.
-- The correlation remains close to zero, suggesting that even after accounting for a 12-month delay
-- Also, removing long-term trends, there is limited evidence of a strong relationship between changes in inflation and subsequent changes in the Bank Rate abse don the result given.
-- This could mean that other economic factors might play a bigger role in influencing BoE rate such as geopolitical factors (oild prices), labour markets or general growth.

-- Final step: 18 month lagg differencing correlation
WITH cte_diff_18_lag AS (
SELECT I.date_id,
       I.full_date,
       B.rate - LAG(B.rate, 1) OVER (ORDER BY I.full_date) AS rate_diff,
       I.cpih_monthly_rate - LAG(I.cpih_monthly_rate, 1) OVER (ORDER BY I.full_date) AS cpih_diff
FROM inflation AS I
INNER JOIN monthly_bank_rate AS B
ON I.date_id = B.date_id
),
cte_diff_lag18 AS (
SELECT full_date,
       rate_diff,
       LAG(cpih_diff, 18) OVER (ORDER BY full_date) AS cpih_diff_18mo_lag
FROM cte_diff_18_lag
)
SELECT ROUND(CORR(cpih_diff_18mo_lag, rate_diff)::numeric, 4) AS correlation_diff_lag18
FROM cte_diff_lag18;
-- The 18-month lagged differenced correlation is +0.0249, indicating an extremely weak positive linear relationship.
-- Compared with the 12-month lagged differenced analysis (+0.0324), the relationship becomes slightly weaker.
-- This suggests that extending the lag to 18 months does not strengthen the association between changes in inflation and subsequent changes in the Bank Rate.
-- Overall, the results indicate little evidence of a meaningful linear relationship after removing long-term trends through differencing.


-- Conclusion: I can fairly say that there is no strong linear relationship at the lags tested but more tests are necessary to provide a complete answer of the full picture.
