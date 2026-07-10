with orders as (

    select *
    from {{ ref('fct_trade_in_orders') }}

)

select
    zustand,

    count(*) as auftraege_gesamt,
    count(*) filter (where ist_abgeschlossen) as auftraege_abgeschlossen,
    count(*) filter (where ist_storniert) as auftraege_storniert,
    count(*) filter (where ist_rueckgabe) as auftraege_rueckgabe,

    {{ get_rate('ist_abgeschlossen', alias_name="konversionsrate") }},
    {{ get_rate('ist_storniert', alias_name="stornoquote") }},
    {{ get_rate('ist_rueckgabe', alias_name="rueckgabequote") }},

    round(avg(ankaufswert_euro)::numeric, 2) as avg_angebotswert_euro,
    round(avg(tatsaechlicher_ankaufswert_euro)::numeric, 2) as avg_tatsaechlicher_ankaufswert_euro

from orders
group by zustand
order by konversionsrate desc
