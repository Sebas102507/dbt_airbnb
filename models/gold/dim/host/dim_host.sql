-- This dbt model selects the most recent, active records for each host
-- from the historical host snapshot table (SCD Type 2).

SELECT
    * -- Select all columns from the host snapshot table.
FROM
    {{ ref('scd_host') }} -- Reference the 'scd_host' snapshot table.
WHERE
    dbt_valid_to IS NULL -- Filter for records where 'dbt_valid_to' is NULL.
                         -- In a dbt snapshot, a NULL value in this column signifies
                         -- that the record is the current and active version.