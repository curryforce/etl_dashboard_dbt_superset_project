with orders as (

    select *
    from {{ ref('fct_trade_in_orders') }}

)

select
    count(*) as auftraege_gesamt,
    count(*) filter (where ist_abgeschlossen) as auftraege_abgeschlossen,
    count(*) filter (where ist_storniert) as auftraege_storniert,

    {{ get_rate('ist_abgeschlossen', alias_name="konversionsrate") }},
    {{ get_rate('ist_storniert', alias_name="stornoquote") }}

from orders
group by lead_id