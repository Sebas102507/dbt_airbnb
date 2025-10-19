-- This dbt model uses a custom macro ('get_unique_versions') to create a clean,
-- de-duplicated, and versioned table of hosts. It identifies the most recent
-- version of each host based on the scrape date and only processes new or updated records.

-- Define a Jinja variable that holds a list of columns.
-- These are the specific columns the macro will monitor for changes. If any of these
-- columns change for a given host, it will be treated as a new version of that host.
{% set host_check_cols = [
    'host_id',
    'host_name',
    'host_since',
    'is_superhost',
    'scraped_date'
] %}

-- Call the custom dbt macro 'get_unique_versions'.
-- This macro encapsulates the logic for de-duplication and incremental processing.
{{
    get_unique_versions(
        source_model=ref('clean_listings_silver'),
        unique_key='host_id',
        order_by_key='scraped_date',
        check_cols=host_check_cols,
        incremental_key='scraped_date'
    )
}}
