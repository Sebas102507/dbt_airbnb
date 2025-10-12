SELECT
    -- This Jinja loop iterates through every column in the source table
    {% for col in adapter.get_columns_in_relation(source('bronze', 'census_g02_nsw_lga_bronze')) %}
        
        -- If the column is the LGA code, apply the special renaming rule
        {% if col.name == 'LGA_CODE_2016' %}
            "{{ col.name }}" AS lga_code
        
        -- For all other columns, simply convert the name to lowercase
        {% else %}
            "{{ col.name }}" AS {{ col.name | lower }}
        {% endif %}
        
        -- Adds a comma after each column, except for the last one
        {% if not loop.last %},{% endif %}

    {% endfor %}
FROM
    {{ source('bronze', 'census_g02_nsw_lga_bronze') }}