{% set host_check_cols = [
    'host_id',
    'host_name',
    'host_since',
    'is_superhost',
    'scraped_date'
] %}

{{
    get_unique_versions(
        source_model=ref('clean_listings_silver'),
        unique_key='host_id',
        order_by_key='scraped_date',
        check_cols=host_check_cols
    )
}}
