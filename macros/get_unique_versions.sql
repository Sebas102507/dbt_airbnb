{% macro get_unique_versions(source_model, unique_key, order_by_key, check_cols, incremental_key=None) %}

WITH source_data AS (
    SELECT * FROM {{ source_model }}

    {# This is the new block for incremental filtering #}
    {% if is_incremental() and incremental_key %}
    
    -- Filter for records that are newer than the latest record in this model
    WHERE {{ incremental_key }} > (SELECT max({{ incremental_key }}) FROM {{ this }})

    {% endif %}
),

distinct_data AS (
    -- First, select the distinct combinations of all columns from the source data
    SELECT DISTINCT *
    FROM source_data
),

data_hashed AS (
    SELECT
        *,
        -- This Jinja block dynamically creates a list of columns to hash,
        -- excluding the unique key and the ordering key from the check_cols list.
        {%- set cols_to_hash = [] -%}
        {%- for col in check_cols -%}
            {%- if col != unique_key and col != order_by_key -%}
                {%- do cols_to_hash.append(col) -%}
            {%- endif -%}
        {%- endfor -%}

        -- This part dynamically builds the hash from the generated list of columns
        MD5(
            {% for col in cols_to_hash %}
                COALESCE(CAST({{ col }} AS VARCHAR), '')
                {% if not loop.last %} || '|' || {% endif %}
            {% endfor %}
        ) AS data_hash
    FROM distinct_data
),

data_with_previous_state AS (
    SELECT
        *,
        LAG(data_hash, 1) OVER (
            PARTITION BY {{ unique_key }} 
            ORDER BY {{ order_by_key }}
        ) AS previous_data_hash
    FROM data_hashed
)

-- The final SELECT now explicitly lists the original columns from the check_cols list,
-- ensuring the intermediate hash columns are not in the final output.
SELECT
    {% for col in check_cols %}
        {{ col }}{% if not loop.last %},{% endif %}
    {% endfor %}
FROM data_with_previous_state
WHERE 
    data_hash <> previous_data_hash
    OR previous_data_hash IS NULL

{% endmacro %}

