with orders as (

    select *
    from {{ ref('fct_trade_in_orders') }}

)

select
    count(*) as auftraege_gesamt,
    count(*) filter (where ist_abgeschlossen) as auftraege_abgeschlossen,
    count(*) filter (where ist_storniert) as auftraege_storniert,


    {{ get_rate('ist_abgeschlossen', alias_name="konversionsrate") }},
    {{ get_rate('ist_storniert', alias_name="stornoquote") }},

    round(avg(ankaufswert_euro)::numeric, 2) as avg_angebotswert_euro,
    round(avg(tatsaechlicher_ankaufswert_euro)::numeric, 2) as avg_tatsaechlicher_ankaufswert_euro,
    round(sum(tatsaechlicher_ankaufswert_euro)::numeric, 2) as summe_tatsaechlicher_ankaufswert_euro

from orders
