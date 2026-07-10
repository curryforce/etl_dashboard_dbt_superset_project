with mapping as(
    select *
    from {{ ref("stg_status_mapping") }}
),

trade_data as (
    select * 
    from {{ ref("stg_trade_in_orders") }}
)

select
t.*,
-- LP_S92 taucht in den Bestelldaten auf, fehlt aber im status_mapping-Seed -> Fallback statt stillem NULL
coalesce(m.beschreibung, 'Unbekannter Status (' || t.bearbeitungsstatus || ')') as beschreibung,
t.ankaufswert / 100.0 as ankaufswert_euro,
t.tatsaechlicher_ankaufswert / 100.0 as tatsaechlicher_ankaufswert_euro
from trade_data as t
left join mapping as m
    on t.bearbeitungsstatus= m.bearbeitungsstatus
-- Gefiltert auf Fälle, in denen die Lead-ID nicht null ist
where t.lead_id is not NULL 
