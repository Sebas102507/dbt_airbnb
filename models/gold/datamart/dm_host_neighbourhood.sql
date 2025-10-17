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
scd_host AS (
    SELECT * FROM {{ ref('scd_host') }}
),

-- Aggregate revenue by host's LGA and month
monthly_agg AS (
    SELECT
        dim_lga.lga_name AS host_neighbourhood_lga,
        dim_lga.lga_code,
        dim_date.calendar_year,
        dim_date.month_name,
        dim_date.month_of_year,
        COUNT(DISTINCT scd_host.host_id) AS distinct_hosts,
        SUM(
            CASE
                WHEN fct_listings.has_availability THEN (30 - fct_listings.availability_30) * fct_listings.price
                ELSE 0
            END
        ) AS total_estimated_revenue_active_listing
    FROM fct_listings
    -- Join to scd_host to get the natural host_id
    JOIN scd_host
        -- Corrected the column name in the join condition below
        ON fct_listings.scd_host_id = scd_host.dbt_scd_id
    LEFT JOIN dim_date ON fct_listings.date_id = dim_date.date_id
    JOIN dim_suburb
        ON fct_listings.host_suburb_id = dim_suburb.suburb_id
    JOIN dim_lga
        ON dim_suburb.lga_code = dim_lga.lga_code
    GROUP BY
        dim_lga.lga_name,
        dim_lga.lga_code,
        dim_date.calendar_year,
        dim_date.month_name,
        dim_date.month_of_year
)

-- Final calculations and formatting
SELECT
    host_neighbourhood_lga,
    lga_code,
    month_name,
    month_of_year,
    calendar_year,
    distinct_hosts,
    ROUND(total_estimated_revenue_active_listing::NUMERIC, 2) AS total_estimated_revenue_active_listing,
    ROUND((total_estimated_revenue_active_listing / NULLIF(distinct_hosts, 0))::NUMERIC, 2) AS estimated_revenue_per_host
FROM
    monthly_agg
ORDER BY
    host_neighbourhood_lga,
    calendar_year,
    month_of_year