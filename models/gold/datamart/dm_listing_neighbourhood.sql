-- This dbt model creates a monthly aggregated summary of Airbnb listings at the neighbourhood level.
-- It calculates key metrics like active listing rates, pricing, host density, and revenue,
-- and also computes month-over-month percentage changes for key trends.

-- =================================================================
-- 1. SOURCE CTEs: Import necessary tables from the data warehouse
-- =================================================================

-- Import the central fact table containing core listing metrics and foreign keys.
WITH fct_listings AS (
    SELECT * FROM {{ ref('fact_listing') }}
),
-- Import the historical (SCD Type 2) host table to get host-specific details.
scd_host AS (
    SELECT * FROM {{ ref('scd_host') }}
),
-- Import the historical (SCD Type 2) property table.
scd_property AS (
    SELECT * FROM {{ ref('scd_property') }}
),
-- Import the date dimension for time-based grouping and filtering.
dim_date AS (
    SELECT * FROM {{ ref('dim_date') }}
),
-- Import the suburb dimension to get neighbourhood names.
dim_suburb AS (
    SELECT * FROM {{ ref('dim_suburb') }}
),

-- =================================================================
-- 2. ENRICHMENT: Join all sources into a single, wide table
-- =================================================================

-- This CTE denormalizes the data by joining the fact table with all the dimension tables.
-- The result is a single, enriched table where each row represents a listing with all its associated attributes.
enriched_listings AS (
    SELECT
        fct_listings.*,
        dim_date.month_name,
        dim_date.calendar_year,
        dim_suburb.suburb_name AS listing_neighbourhood,
        scd_host.is_superhost,
        scd_host.host_id -- Include the natural key for host to allow for distinct counting.
    FROM fct_listings
    LEFT JOIN dim_date ON fct_listings.date_id = dim_date.date_id
    LEFT JOIN scd_host 
        ON fct_listings.scd_host_id = scd_host.dbt_scd_id
    LEFT JOIN scd_property
        ON fct_listings.scd_property_id = scd_property.dbt_scd_id
    LEFT JOIN dim_suburb
        ON fct_listings.property_suburb_id = dim_suburb.suburb_id
),

-- =================================================================
-- 3. AGGREGATION: Group by month and neighbourhood to calculate KPIs
-- =================================================================

-- This CTE rolls up the enriched listing data to a monthly level for each neighbourhood.
-- It calculates all the key business metrics needed for the final report.
monthly_agg AS (
    SELECT
        listing_neighbourhood,
        calendar_year,
        month_name,
        COUNT(*) AS total_listings,
        -- Count only listings that are marked as available.
        SUM(CASE WHEN has_availability THEN 1 ELSE 0 END) AS active_listings,
        (COUNT(*) - SUM(CASE WHEN has_availability THEN 1 ELSE 0 END)) AS inactive_listings,
        -- Calculate price metrics only for available listings to avoid skewing data.
        MIN(CASE WHEN has_availability THEN price END) AS min_price,
        MAX(CASE WHEN has_availability THEN price END) AS max_price,
        AVG(CASE WHEN has_availability THEN price END) AS avg_price,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CASE WHEN has_availability THEN price END) AS median_price,
        COUNT(DISTINCT host_id) AS distinct_hosts,
        COUNT(DISTINCT CASE WHEN is_superhost THEN host_id END) AS superhost_count,
        AVG(CASE WHEN has_availability THEN review_scores_rating END) AS avg_review_score,
        -- Estimate the number of stays by calculating booked days in the last 30 days.
        SUM(CASE WHEN has_availability THEN (30 - availability_30) ELSE 0 END) AS total_stays,
        -- Estimate revenue by multiplying the number of stays by the nightly price.
        SUM(CASE WHEN has_availability THEN (30 - availability_30) * price ELSE 0 END) AS estimated_revenue
    FROM enriched_listings
    GROUP BY
        listing_neighbourhood,
        calendar_year,
        month_name
),

-- =================================================================
-- 4. COMPARISON: Use window functions to get previous month's data
-- =================================================================

-- This CTE uses the LAG window function to fetch the active and inactive listing counts from the previous month.
-- This is necessary to calculate month-over-month percentage changes in the final step.
monthly_comparison AS (
    SELECT
        *,
        LAG(active_listings, 1) OVER (PARTITION BY listing_neighbourhood ORDER BY calendar_year, month_name) AS prev_month_active_listings,
        LAG(inactive_listings, 1) OVER (PARTITION BY listing_neighbourhood ORDER BY calendar_year, month_name) AS prev_month_inactive_listings
    FROM monthly_agg
)

-- =================================================================
-- 5. FINAL SELECTION: Format output and calculate final ratios/growth rates
-- =================================================================

-- The final SELECT statement cleans up the data for presentation.
-- It calculates rates (e.g., active listings rate, superhost rate) and the month-over-month percentage changes.
SELECT
    listing_neighbourhood,
    month_name,
    calendar_year,
    -- Calculate rates, using NULLIF to prevent division-by-zero errors.
    ROUND(((active_listings::FLOAT / NULLIF(total_listings, 0)) * 100)::NUMERIC, 2) AS active_listings_rate,
    ROUND(((superhost_count::FLOAT / NULLIF(distinct_hosts, 0)) * 100)::NUMERIC, 2) AS superhost_rate,
    min_price,
    max_price,
    ROUND(avg_price::NUMERIC, 2) AS avg_price,
    ROUND(median_price::NUMERIC, 2) AS median_price,
    distinct_hosts,
    ROUND(avg_review_score::NUMERIC, 2) AS avg_review_score,
    total_stays,
    ROUND((CASE WHEN active_listings > 0 THEN estimated_revenue / active_listings ELSE 0 END)::NUMERIC, 2) AS avg_revenue_per_active_listing,
    -- Calculate the percentage change from the previous month using the lagged values.
    ROUND((CASE WHEN prev_month_active_listings > 0 THEN (active_listings - prev_month_active_listings)::FLOAT / prev_month_active_listings * 100 ELSE NULL END)::NUMERIC, 2) AS pct_change_active_listings,
    ROUND((CASE WHEN prev_month_inactive_listings > 0 THEN (inactive_listings - prev_month_inactive_listings)::FLOAT / prev_month_inactive_listings * 100 ELSE NULL END)::NUMERIC, 2) AS pct_change_inactive_listings
FROM
    monthly_comparison
ORDER BY
    listing_neighbourhood,
    calendar_year,
    month_name;