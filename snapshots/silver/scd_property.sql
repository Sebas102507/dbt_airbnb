-- This block defines a dbt snapshot named 'scd_property'.
-- Its purpose is to create a Type 2 Slowly Changing Dimension (SCD) table,
-- which tracks the history of all changes to each property/listing over time.

{% snapshot scd_property %}

{{
    config(
      target_schema='silver',
      strategy='timestamp',
      updated_at='scraped_date',
      unique_key='listing_id'
    )
}}

SELECT * FROM {{ ref('stg_property_silver') }}

{% endsnapshot %}