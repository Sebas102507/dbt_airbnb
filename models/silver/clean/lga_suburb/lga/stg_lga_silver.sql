-- This dbt model creates a clean, de-duplicated dimension table for Local Government Areas (LGAs).
-- It ensures that there is only one unique record for each LGA.

SELECT DISTINCT
    lga_code,
    lga_name
FROM
    -- Reference the clean suburb-to-LGA mapping table from the Silver Layer.
    -- The DISTINCT clause will collapse this down to one row per unique LGA.
    {{ ref('clean_lga_suburb_silver') }}