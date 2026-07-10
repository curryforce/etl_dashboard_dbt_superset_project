with orders as (

    select *
    from {{ ref('int_trade_in_orders_with_status') }}

)

-- single source of truth ansatz
-- fct table als data hub

select
    id as order_id,
    lead_id,
    auftragsdatum,
    cast(auftragsdatum as date) as auftragsdatum_tag,

    name as geraet_modell,
    altgeraet as geraet_beschreibung,
    farbe,
    memory as speicherplatz,
    zustand,

    bearbeitungsstatus,
    beschreibung as status_beschreibung,

    case
        when bearbeitungsstatus = 'draft' then 'Draft'
        when bearbeitungsstatus in ('LP_S0', 'LP_S1') then 'Angelegt'
        when bearbeitungsstatus in ('LP_S2', 'LP_S3', 'LP_S4', 'LP_S6', 'LP_S42', 'LP_S43', 'LP_S44', 'LP_S45', 'LP_S81') then 'In Pruefung'
        when bearbeitungsstatus in ('LP_S20', 'LP_S21', 'LP_S22', 'LP_S23', 'LP_S24', 'LP_S25', 'LP_S26', 'LP_S27') then 'Abweichende Einschaetzung'
        when bearbeitungsstatus in ('LP_S10', 'LP_S11') then 'Abgeschlossen'
        when bearbeitungsstatus = 'LP_S9' then 'Storniert'
        when bearbeitungsstatus in ('LP_S14', 'LP_S15', 'LP_S16', 'LP_S47') then 'Rueckgabe'
        when bearbeitungsstatus = 'LP_S12' then 'Fehlerhaft'
        else 'Unbekannt'
    end as status_gruppe,

    bearbeitungsstatus in ('LP_S10', 'LP_S11') as ist_abgeschlossen,
    bearbeitungsstatus = 'LP_S9' as ist_storniert,
    bearbeitungsstatus in ('LP_S14', 'LP_S15', 'LP_S16', 'LP_S47') as ist_rueckgabe,
    
    nullif(ankaufswert_euro, 0) as ankaufswert_euro,
    nullif(tatsaechlicher_ankaufswert_euro, 0) as tatsaechlicher_ankaufswert_euro,
    ankaufswert_euro is not null and ankaufswert_euro <> 0 as hat_angebotswert,
    tatsaechlicher_ankaufswert_euro is not null and tatsaechlicher_ankaufswert_euro <> 0 as hat_tatsaechlichen_wert
from orders