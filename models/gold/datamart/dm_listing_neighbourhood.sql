WITH fct_listings AS (
    SELECT * FROM {{ ref('fact_listing') }}
),
scd_host AS (
    SELECT * FROM {{ ref('scd_host') }}
),
scd_property AS (
    SELECT * FROM {{ ref('scd_property') }}
),
dim_date AS (
    SELECT * FROM {{ ref('dim_date') }}
),
dim_suburb AS (
    SELECT * FROM {{ ref('dim_suburb') }}
),

-- First, join the fact table to the historical dimension tables
-- to get the correct attributes for each day.
enriched_listings AS (
    SELECT
        fct_listings.*,
        dim_date.month_name,
        dim_date.calendar_year,
        dim_suburb.suburb_name AS listing_neighbourhood,
        scd_host.is_superhost
    FROM fct_listings
    LEFT JOIN dim_date ON fct_listings.date_id = dim_date.date_id
    LEFT JOIN scd_host 
        ON fct_listings.scd_host_id = scd_host.dbt_scd_id
    LEFT JOIN scd_property
        ON fct_listings.scd_property_id = scd_property.dbt_scd_id
    LEFT JOIN dim_suburb
        ON fct_listings.property_suburb_id = dim_suburb.suburb_id
),

-- Aggregate metrics by neighbourhood and month
monthly_agg AS (
    SELECT
        listing_neighbourhood,
        calendar_year,
        month_name,
        -- Active vs Inactive Listings
        COUNT(*) AS total_listings,
        SUM(CASE WHEN has_availability THEN 1 ELSE 0 END) AS active_listings,
        (COUNT(*) - SUM(CASE WHEN has_availability THEN 1 ELSE 0 END)) AS inactive_listings,
        -- Price Metrics for Active Listings
        MIN(CASE WHEN has_availability THEN price END) AS min_price,
        MAX(CASE WHEN has_availability THEN price END) AS max_price,
        AVG(CASE WHEN has_availability THEN price END) AS avg_price,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CASE WHEN has_availability THEN price END) AS median_price,
        -- Host Metrics
        COUNT(DISTINCT scd_host_id) AS distinct_hosts,
        COUNT(DISTINCT CASE WHEN is_superhost THEN scd_host_id END) AS superhost_count,
        -- Review Metrics for Active Listings
        AVG(CASE WHEN has_availability THEN review_scores_rating END) AS avg_review_score,
        -- Revenue and Stay Metrics for Active Listings
        SUM(CASE WHEN has_availability THEN (30 - availability_30) ELSE 0 END) AS total_stays,
        SUM(CASE WHEN has_availability THEN (30 - availability_30) * price ELSE 0 END) AS estimated_revenue
    FROM enriched_listings
    GROUP BY
        listing_neighbourhood,
        calendar_year,
        month_name
),

-- Use window functions to calculate month-over-month changes
monthly_comparison AS (
    SELECT
        *,
        LAG(active_listings, 1) OVER (PARTITION BY listing_neighbourhood ORDER BY calendar_year, month_name) AS prev_month_active_listings,
        LAG(inactive_listings, 1) OVER (PARTITION BY listing_neighbourhood ORDER BY calendar_year, month_name) AS prev_month_inactive_listings
    FROM monthly_agg
)

-- Final selection and calculation of rates and percentages
SELECT
    listing_neighbourhood,
    month_name,
    calendar_year,
    -- Rates
    ROUND(((active_listings::FLOAT / total_listings) * 100)::NUMERIC, 2) AS active_listings_rate,
    ROUND(((superhost_count::FLOAT / distinct_hosts) * 100)::NUMERIC, 2) AS superhost_rate,
    -- Price
    min_price,
    max_price,
    ROUND(avg_price::NUMERIC, 2) AS avg_price,
    ROUND(median_price::NUMERIC, 2) AS median_price,
    distinct_hosts,
    ROUND(avg_review_score::NUMERIC, 2) AS avg_review_score,
    total_stays,
    ROUND((CASE WHEN active_listings > 0 THEN estimated_revenue / active_listings ELSE 0 END)::NUMERIC, 2) AS avg_revenue_per_active_listing,
    -- Percentage Change MoM
    ROUND((CASE WHEN prev_month_active_listings > 0 THEN (active_listings - prev_month_active_listings)::FLOAT / prev_month_active_listings * 100 ELSE NULL END)::NUMERIC, 2) AS pct_change_active_listings,
    ROUND((CASE WHEN prev_month_inactive_listings > 0 THEN (inactive_listings - prev_month_inactive_listings)::FLOAT / prev_month_inactive_listings * 100 ELSE NULL END)::NUMERIC, 2) AS pct_change_inactive_listings
FROM
    monthly_comparison
ORDER BY
    listing_neighbourhood,
    month_name,
    calendar_year