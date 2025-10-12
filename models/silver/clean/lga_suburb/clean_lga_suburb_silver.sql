SELECT
    -- Casts the LGA code to a string and renames the column to lowercase
    nlcb."LGA_CODE"::VARCHAR AS lga_code,

    -- Converts the LGA name to uppercase and renames the column to lowercase
    UPPER(nlcb."LGA_NAME") AS lga_name,

    -- Converts the suburb name to uppercase and renames the column to lowercase
    UPPER(nlsb."SUBURB_NAME") AS suburb_name
FROM
    {{ source('bronze', 'nsw_lga_code_bronze') }} AS nlcb
JOIN
    {{ source('bronze', 'nsw_lga_suburb_bronze') }} AS nlsb
    -- Joins the tables on a case-insensitive match of the LGA name
    ON UPPER(nlcb."LGA_NAME") = UPPER(nlsb."LGA_NAME")
