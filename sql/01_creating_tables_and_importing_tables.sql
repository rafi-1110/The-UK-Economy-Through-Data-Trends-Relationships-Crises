-- Craeting tables, importing the CSV files, and establishing the data relationships.

CREATE TABLE dim_date(
    full_date DATE,
    date_id INTEGER PRIMARY KEY,
    year INTEGER,
    quarter INTEGER,
    month INTEGER,
    is_post_covid BOOLEAN);

CREATE TABLE inflation(
    full_date DATE,
    date_id INTEGER PRIMARY KEY REFERENCES dim_date(date_id),
    year INTEGER,
    quarter INTEGER,
    month INTEGER,
    is_post_covid BOOLEAN,
    frequency VARCHAR(20),
    cpih_index NUMERIC,
    cpih_annual_rate NUMERIC,
    cpih_monthly_rate NUMERIC);

CREATE TABLE monthly_gdp(
    full_date DATE,
    date_id INTEGER PRIMARY KEY REFERENCES dim_date(date_id),
    year INTEGER,
    quarter INTEGER,
    month INTEGER,
    is_post_covid BOOLEAN,
    date VARCHAR(20),
    gdp_index NUMERIC,
    gdp_growth_yoy NUMERIC,
    gdp_growth_3m_yoy NUMERIC);

CREATE TABLE monthly_unemployment(
    full_date DATE,
    date_id INTEGER PRIMARY KEY REFERENCES dim_date(date_id),
    year INTEGER,
    quarter INTEGER,
    month INTEGER,
    is_post_covid BOOLEAN,
    frequency VARCHAR(20),
    unemployment_rate NUMERIC);

CREATE TABLE monthly_bank_rate(
    full_date DATE,
    date_id INTEGER PRIMARY KEY REFERENCES dim_date(date_id),
    year INTEGER,
    quarter INTEGER,
    month INTEGER,
    is_post_covid BOOLEAN,
    date_changed DATE,
    rate NUMERIC);