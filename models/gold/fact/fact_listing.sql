WITH listings_source AS (
    -- Select all the clean data from the Silver layer
    SELECT * FROM {{ ref('clean_listings_silver') }}
)

SELECT
    -- Foreign Keys to link to the dimension tables
    -- These are now the surrogate keys from the historical snapshot tables
    scd_hosts.dbt_scd_id AS scd_host_id,
    scd_properties.dbt_scd_id AS scd_property_id,
    
    -- Foreign keys for the role-playing location dimension
    dim_property_suburb.suburb_id AS property_suburb_id,
    dim_host_suburb.suburb_id AS host_suburb_id,

    dim_date.date_id as date_id,

    -- Metrics (the "facts")
    listings_source.price,
    listings_source.has_availability,
    listings_source.availability_30,
    listings_source.number_of_reviews,
    listings_source.review_scores_rating,
    listings_source.review_scores_accuracy,
    listings_source.review_scores_cleanliness,
    listings_source.review_scores_checkin,
    listings_source.review_scores_communication,
    listings_source.review_scores_value
FROM
    listings_source
LEFT JOIN {{ ref('dim_date') }} AS dim_date
    ON listings_source.scraped_date = dim_date.full_date
LEFT JOIN {{ ref('dim_suburb') }} AS dim_property_suburb
    ON listings_source.listing_neighbourhood = dim_property_suburb.suburb_name
LEFT JOIN {{ ref('dim_suburb') }} AS dim_host_suburb
    ON listings_source.host_neighbourhood = dim_host_suburb.suburb_name
LEFT JOIN {{ ref('scd_host') }} AS scd_hosts
    ON listings_source.host_id = scd_hosts.host_id
    AND listings_source.scraped_date >= scd_hosts.dbt_valid_from
    AND (listings_source.scraped_date < scd_hosts.dbt_valid_to OR scd_hosts.dbt_valid_to IS NULL)
LEFT JOIN {{ ref('scd_property') }} AS scd_properties
    ON listings_source.listing_id = scd_properties.listing_id
    AND listings_source.scraped_date >= scd_properties.dbt_valid_from
    AND (listings_source.scraped_date < scd_properties.dbt_valid_to OR scd_properties.dbt_valid_to IS NULL)