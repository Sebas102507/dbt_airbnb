-- This dbt model selects all data from the staged suburb table.
-- It serves as a clean, standardized source for suburb-to-LGA mapping information,
-- making it ready for use in downstream models that join different geographic datasets.

SELECT
    * -- Select all columns from the staged suburb table.
FROM
    -- Reference the 'stg_suburb_silver' model, which contains the cleaned
    -- suburb and their corresponding LGA names from the Silver Layer.
    {{ ref('stg_suburb_silver') }}