select
    -- IDs and Dates
    "LISTING_ID"::varchar as listing_id,
    "SCRAPED_DATE"::date as scraped_date,
    "HOST_ID"::varchar as host_id,
    to_date("HOST_SINCE", 'DD/MM/YYYY') as host_since,

    -- Host Attributes
    trim("HOST_NAME")::varchar as host_name,
    ("HOST_IS_SUPERHOST" = 't') as is_superhost,
    -- Impute null neighbourhoods with 'UNKNOWN'
    coalesce(trim(upper("HOST_NEIGHBOURHOOD")), 'UNKNOWN')::varchar
    as host_neighbourhood,

    -- Property Attributes
    trim(upper("LISTING_NEIGHBOURHOOD"))::varchar as listing_neighbourhood,
    trim(upper("PROPERTY_TYPE"))::varchar as property_type,
    trim(upper("ROOM_TYPE"))::varchar as room_type,
    "ACCOMMODATES"::integer as accommodates,

    -- Metrics and Flags
    "PRICE"::numeric(10, 2) as price,
    ("HAS_AVAILABILITY" = 't') as has_availability,
    "AVAILABILITY_30"::integer as availability_30,
    "NUMBER_OF_REVIEWS"::integer as number_of_reviews,
    -- Impute null review scores with 0, as they indicate no reviews
    coalesce("REVIEW_SCORES_RATING", 0)::integer as review_scores_rating,
    coalesce("REVIEW_SCORES_ACCURACY", 0)::integer as review_scores_accuracy,
    coalesce("REVIEW_SCORES_CLEANLINESS", 0)::integer as review_scores_cleanliness,
    coalesce("REVIEW_SCORES_CHECKIN", 0)::integer as review_scores_checkin,
    coalesce("REVIEW_SCORES_COMMUNICATION", 0)::integer as review_scores_communication,
    coalesce("REVIEW_SCORES_VALUE", 0)::integer as review_scores_value

from {{ source("bronze", "listings_bronze") }}

-- Remove the 3 rows with missing critical host information
where
    "HOST_SINCE" is not null
    and "HOST_NAME" is not null
    and "HOST_IS_SUPERHOST" is not null
