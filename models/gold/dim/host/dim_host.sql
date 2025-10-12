SELECT
    *
FROM
    {{ ref('scd_host') }}
WHERE
    dbt_valid_to IS NULL