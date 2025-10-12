WITH date_series AS (
    -- Generates a series of dates from Jan 1, 2010 to Dec 31, 2030.
    -- This range can be adjusted as needed for your project.
    SELECT
        CAST(generate_series AS DATE) AS full_date
    FROM
        generate_series(
            '2010-01-01'::timestamp,
            '2030-12-31'::timestamp,
            '1 day'::interval
        )
)

SELECT
    -- A numeric unique identifier (integer) in YYYYMMDD format
     TO_CHAR(full_date, 'YYYYMMDD')::VARCHAR AS date_id,
    full_date,
    TO_CHAR(full_date, 'Day') AS day_of_week_name,
    EXTRACT(ISODOW FROM full_date) AS day_of_week,
    EXTRACT(DAY FROM full_date) AS day_of_month,
    EXTRACT(DOY FROM full_date) AS day_of_year,
    EXTRACT(WEEK FROM full_date) AS week_of_year,
    EXTRACT(MONTH FROM full_date) AS month_of_year,
    TO_CHAR(full_date, 'Month') AS month_name,
    EXTRACT(QUARTER FROM full_date) AS calendar_quarter,
    EXTRACT(YEAR FROM full_date) AS calendar_year
FROM
    date_series