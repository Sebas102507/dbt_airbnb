{% set host_check_cols = [
    'listing_id',
    'scraped_date',
    'property_type',
    'room_type'
] %}


{{
    get_unique_versions(
        source_model=ref('clean_listings_silver'),
        unique_key='listing_id',
        order_by_key='scraped_date',
        check_cols=host_check_cols
    )
}}