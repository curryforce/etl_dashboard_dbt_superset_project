with raw_csv_data as (
    select *
    from {{ source('raw', 'trade_in_orders')}}
)

select
    cast(id as integer) as id,
    cast("Lead-ID" as bigint) as lead_id,                       
    cast("Auftragsdatum" as timestamp) as auftragsdatum,       
    coalesce(cast("Altgerät" as varchar), 'unbekannt') as altgeraet,                   
    coalesce(cast("Name" as varchar), 'unbekannt') as name,                            
    coalesce(cast("Farbe" as varchar), 'unbekannt') as farbe,                          
    coalesce(cast("Memory" as varchar), 'unbekannt') as memory,                        
    coalesce(cast("Bearbeitungsstatus" as varchar), 'unbekannt') as bearbeitungsstatus, 
    coalesce(cast("Zustand" as varchar), 'unbekannt') as zustand,                      
    cast("Ankaufswert" as numeric(12,2)) as ankaufswert,        
    cast("Tatsächlicher Ankaufswert" as numeric(12,2)) as tatsaechlicher_ankaufswert

from raw_csv_data