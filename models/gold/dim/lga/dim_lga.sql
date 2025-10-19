-- This dbt model selects all columns from the staged LGA (Local Government Area) table.
-- Its primary purpose is often to act as a clean pass-through or to apply project-level configurations
-- before the data is used in downstream, more complex models.

SELECT
    * -- Select all columns from the staged LGA table.
FROM
    {{ ref('stg_lga_silver') }} -- Reference the 'stg_lga_silver' model, which contains the cleaned LGA data.