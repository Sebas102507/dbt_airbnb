-- This dbt model selects the most recent, active records for each property
-- from the historical property snapshot table (SCD Type 2).
-- It effectively creates a view of the current state of all listings.

SELECT
    * -- Select all columns from the property snapshot table.
FROM
    {{ ref('scd_property') }} -- Reference the 'scd_property' snapshot table.
WHERE
    dbt_valid_to IS NULL -- Filter for records where 'dbt_valid_to' is NULL.
                         -- In a dbt snapshot, a NULL value in this column signifies
                         -- that this version of the record is currently active.