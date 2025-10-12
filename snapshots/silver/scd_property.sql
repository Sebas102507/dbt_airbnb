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