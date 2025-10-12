SELECT DISTINCT
    lga_code,
    lga_name
FROM
    {{ ref('clean_lga_suburb_silver') }}