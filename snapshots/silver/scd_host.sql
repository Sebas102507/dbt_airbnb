-- This block defines a dbt snapshot named 'scd_host'.
-- Its purpose is to create a Type 2 Slowly Changing Dimension (SCD) table,
-- which tracks the history of changes to each host over time.

{% snapshot scd_host %}

{{
    config(
      target_schema='silver',
      strategy='timestamp',
      updated_at='scraped_date',
      unique_key='host_id'
    )
}}

SELECT * FROM {{ ref('stg_host_silver') }}

{% endsnapshot %}