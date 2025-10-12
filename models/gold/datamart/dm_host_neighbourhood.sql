WITH fct_listings AS (
    SELECT * FROM {{ ref('fact_listing') }}
),
dim_suburb AS (
    SELECT * FROM {{ ref('dim_suburb') }}
),
dim_lga AS (
    SELECT * FROM {{ ref('dim_lga') }}
),
dim_date AS (
    SELECT * FROM {{ ref('dim_date') }}
),

-- Aggregate revenue by host's LGA and month
monthly_agg AS (
    SELECT
        -- Get the LGA name from the dedicated LGA dimension
        dim_lga.lga_name AS host_neighbourhood_lga,
        dim_date.calendar_year,
        dim_date.month_name,
        COUNT(DISTINCT fct_listings.scd_host_id) AS distinct_hosts,
        -- Calculate estimated revenue per listing snapshot for active listings
        SUM(
            CASE
                WHEN fct_listings.has_availability THEN (30 - fct_listings.availability_30) * fct_listings.price
                ELSE 0
            END
        ) AS total_estimated_revenue
    FROM fct_listings
    -- Join to date dimension to get month and year for grouping
    LEFT JOIN dim_date ON fct_listings.date_id = dim_date.date_id
    -- Join to suburb dimension using the HOST's suburb ID from the fact table
    JOIN dim_suburb
        ON fct_listings.host_suburb_id = dim_suburb.suburb_id
    -- Then, join to the LGA dimension to get the official LGA name
    JOIN dim_lga
        ON dim_suburb.lga_code = dim_lga.lga_code
    GROUP BY
        dim_lga.lga_name,
        dim_date.calendar_year,
        dim_date.month_name
)

-- Final calculations and formatting
SELECT
    host_neighbourhood_lga,
    month_name,
    calendar_year,
    distinct_hosts,
    ROUND(total_estimated_revenue::NUMERIC, 2) AS total_estimated_revenue,
    ROUND((total_estimated_revenue / distinct_hosts)::NUMERIC, 2) AS estimated_revenue_per_host
FROM
    monthly_agg
ORDER BY
    host_neighbourhood_lga,
    month_name,
    calendar_year