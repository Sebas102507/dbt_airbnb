SELECT DISTINCT
    MD5(lga_code || '|' || suburb_name) AS suburb_id,
    lga_code,
    suburb_name
FROM
    {{ ref('clean_lga_suburb_silver') }}



