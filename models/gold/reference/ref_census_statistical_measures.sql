-- This model creates the final Gold layer dimension table for the G02 Census data.
-- It simply selects all the clean data from the corresponding Silver staging model.

SELECT
    *
FROM
    {{ ref('stg_census_statistical_measures') }}