with base as (

    select *
    from {{ ref('stg_linkedin_ads__campaign_group_history_tmp') }}

), macro as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_linkedin_ads__campaign_group_history_tmp')),
                staging_columns=get_campaign_group_history_columns()
            )
        }}
    from base

), fields as (

    select 
        id as campaign_group_id,
        name as campaign_group_name,
        account_id,
        backfilled as is_backfilled,
        cast(run_schedule_start as {{ dbt_utils.type_timestamp() }}) as run_schedule_start_at,
        cast(run_schedule_end as {{ dbt_utils.type_timestamp() }}) as run_schedule_end_at,
        cast(last_modified_time as {{ dbt_utils.type_timestamp() }}) as last_modified_at,
        cast(created_time as {{ dbt_utils.type_timestamp() }}) as created_at

    from macro

), valid_dates as (

    select 
        *,
        case 
            when row_number() over (partition by campaign_group_id order by last_modified_at) = 1 then created_at
            else last_modified_at
        end as valid_from,
        lead(last_modified_at) over (partition by campaign_group_id order by last_modified_at) as valid_to
    from fields

), surrogate_key as (

    select 
        *,
        {{ dbt_utils.surrogate_key(['campaign_group_id','last_modified_at']) }} as campaign_group_version_id
    from valid_dates

)

select *
from surrogate_key
