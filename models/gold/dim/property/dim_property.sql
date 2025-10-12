SELECT
    *
FROM
    {{ ref('scd_property') }}
WHERE
    dbt_valid_to IS NULL