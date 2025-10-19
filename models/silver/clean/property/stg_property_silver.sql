-- This dbt model uses a custom macro ('get_unique_versions') to create a clean,
-- de-duplicated, and versioned table of properties/listings. It identifies the most recent
-- version of each listing based on the scrape date and is configured to run incrementally.

-- Define a Jinja variable that holds a list of columns.
-- These are the specific columns the macro will monitor for changes. If any of these
-- columns' values change for a given listing_id, it will be considered a new version.
{% set host_check_cols = [
    'listing_id',
    'scraped_date',
    'property_type',
    'room_type',
    'accommodates'
] %}


-- Call the custom dbt macro 'get_unique_versions'.
-- This macro encapsulates the complex logic for de-duplication and versioning.
{{
    get_unique_versions(
        source_model=ref('clean_listings_silver'),
        unique_key='listing_id',
        order_by_key='scraped_date',
        check_cols=host_check_cols,
        incremental_key='scraped_date'
    )
}}