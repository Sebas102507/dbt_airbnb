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