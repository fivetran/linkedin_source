{% macro extract_url_parameter(field, uri_parameter) -%}

{{ adapter.dispatch('extract_url_parameter', 'linkedin_source') (field, uri_parameter) }}

{% endmacro %}


{% macro default__extract_url_parameter(field, uri_parameter) -%}

{{ dbt_utils.get_url_parameter(field, uri_parameter) }}

{%- endmacro %}


{% macro databricks__extract_url_parameter(field, uri_parameter) -%}

{%- set formatted_uri_parameter = "'" + uri_parameter + "=([^&]+)'" -%}
nullif(regexp_extract({{ field }}, {{ formatted_uri_parameter }}, 1), '')

{%- endmacro %}