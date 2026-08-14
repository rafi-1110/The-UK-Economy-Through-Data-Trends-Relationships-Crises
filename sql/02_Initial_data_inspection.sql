--- Initial table inspection and their contents.

-- The "master calendar".
SELECT *
FROM dim_date
LIMIT 10;

-- The inflation table.
SELECT *
FROM inflation
LIMIT 10;

-- The GDP growth table.
SELECT *
FROM monthly_gdp
LIMIT 10;

-- The unemployment table.
SELECT *
FROM monthly_unemployment
LIMIT 10;

-- The bank rate table.
SELECT *
FROM monthly_bank_rate
LIMIT 10;

--- Data Validation: Although this has been accounted for in Python, I want to check for missing values for our column of interest.

SELECT COUNT(*) AS missing_calendar_values
FROM dim_date
WHERE year IS NULL OR
	  quarter IS NULL OR 
	  month IS NULL;
-- Result:: No missing values for the calendar which was to be expected as this was created manaully in Python earlier. 
-- This also tells us that the first columns, such as "date_id" or "year" or "quarter"..
-- and others will be non-empty as they dereive from the same master calendar.

SELECT COUNT(*) AS missing_inflation_values
FROM inflation
WHERE cpih_annual_rate IS NULL OR
	  cpih_index IS NULL OR 
	  frequency IS NULL;
-- Result:: No missing values for inflation table 

SELECT COUNT(*) AS missing_gdp_values
FROM monthly_gdp
WHERE date IS NULL OR
	  gdp_growth_yoy IS NULL OR 
	  gdp_growth_3m_yoy IS NULL;
-- Result: There 14 instances where the values are null. 

-- Checking if there are any rows where given a selected range of columns if all the values are null in the GDP table.
SELECT *
FROM monthly_gdp
WHERE COALESCE(gdp_growth_yoy, gdp_growth_3m_yoy) IS NULL;
-- Result: It shows that for the entire 1997 year values for gdp index, year on year growth and 3 month year on year growth are not available. 
-- Further analysis will exclude this range.

SELECT COUNT(*) AS missing_unemployment_values
FROM monthly_unemployment
WHERE frequency IS NULL OR
	  unemployment_rate IS NULL;
-- Result: One row with missing value. I expect this to be for the most recent date.

SELECT *
FROM monthly_unemployment
WHERE COALESCE(unemployment_rate) IS NULL;
-- Result: As expected the missing value(s) was for the April 2026 data which was not available when downloading the data

SELECT COUNT(*) AS missing_bank_rate_values
FROM monthly_bank_rate
WHERE date_changed IS NULL OR
	  rate IS NULL;
-- Resul: No missing values here

--- Checking for impossible values such as negative unemployment rates or bank rate (never occirred in the UK)

SELECT *
FROM monthly_unemployment
WHERE unemployment_rate < 0;

SELECT *
FROM monthly_bank_rate
WHERE rate < 0;
-- Result: Both test passed as no values with negative unemployment rates or bank rates were present.