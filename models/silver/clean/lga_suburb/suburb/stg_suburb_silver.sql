-- This dbt model creates a clean, de-duplicated dimension table for suburbs.
-- It generates a unique, deterministic surrogate key for each suburb to be used as a primary key
-- in the data warehouse, which is more reliable for joins than using natural keys like names.

SELECT DISTINCT
    -- Create a surrogate key for each suburb. This is a common data warehousing technique.
    -- It concatenates the business keys ('lga_code' and 'suburb_name') and then hashes them using MD5.
    -- The result is a unique, fixed-length key ('suburb_id') that will always be the same for the same suburb.
    MD5(lga_code || '|' || suburb_name) AS suburb_id,
    
    -- Select the natural key for the Local Government Area.
    lga_code,
    
    -- Select the natural key for the suburb.
    suburb_name
FROM
    -- Reference the clean suburb-to-LGA mapping table from the Silver Layer.
    -- The DISTINCT clause ensures that we only get one record per unique suburb-LGA combination.
    {{ ref('clean_lga_suburb_silver') }}



