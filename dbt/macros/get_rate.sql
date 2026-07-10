{% macro get_rate(condition_column, alias_name, precision=4) %}
    round(
        count(*) filter (where {{ condition_column }})::numeric 
        / nullif(count(*), 0), 
        {{ precision }}
    ) as {{ alias_name }}
{% endmacro %}

