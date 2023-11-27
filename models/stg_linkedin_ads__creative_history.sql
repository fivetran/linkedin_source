{{ config(enabled=var('ad_reporting__linkedin_ads_enabled', True)) }}

with base as (

    select *
    from {{ ref('stg_linkedin_ads__creative_history_tmp') }}

), macro as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_linkedin_ads__creative_history_tmp')),
                staging_columns=get_creative_history_columns()
            )
        }}
    
        {{ fivetran_utils.source_relation(
            union_schema_variable='linkedin_ads_union_schemas', 
            union_database_variable='linkedin_ads_union_databases') 
        }}

    from base

), fields as (

    select
        source_relation,
        id as creative_id,
        campaign_id,
        coalesce(intended_status, status) as status,
        click_uri,
        cast(coalesce(last_modified_at, last_modified_time) as {{ dbt.type_timestamp() }}) as last_modified_at,
        cast(coalesce(created_at, created_time) as {{ dbt.type_timestamp() }}) as created_at,
        row_number() over (partition by source_relation, id order by coalesce(last_modified_at, last_modified_time) desc) = 1 as is_latest_version

    from macro

), url_fields as (

    select 
        *,
        {{ dbt.split_part('click_uri', "'?'", 1) }} as base_url,
        {{ dbt_utils.get_url_host('click_uri') }} as url_host,
        '/' || {{ dbt_utils.get_url_path('click_uri') }} as url_path,
        {{ fivetran_utils.extract_uri_parameter('click_uri', 'utm_source') }} as utm_source,
        {{ fivetran_utils.extract_uri_parameter('click_uri', 'utm_medium') }} as utm_medium,
        {{ fivetran_utils.extract_uri_parameter('click_uri', 'utm_campaign') }} as utm_campaign,
        {{ fivetran_utils.extract_uri_parameter('click_uri', 'utm_content') }} as utm_content,
        {{ fivetran_utils.extract_uri_parameter('click_uri', 'utm_term') }} as utm_term
    
    from fields
)

select *
from url_fields

