# BI-Dashboard -DBT-Postgres-ApacheSuperset 
Ein Dashboard mit KPI-Metriken über Trade-In-Optionen (Verkauf des alten Smartphones) im Rahmen eines Vertragabschlusses für ein neues Endgerät.
Daten im Apache-Superset-Dashboard am Ende der ETL-Strecke:
![Dashboardbild1](media/image.png)
![Dashboardbild1](media/image2.png)

## Was steckt drin?

| Service | Beschreibung | Erreichbar unter |
|---|---|---|
| **PostgreSQL 16** | Analytics-Datenbank. Rohdaten liegen im Schema `raw`. | `localhost:5432` |
| **Loader** | Lädt beim ersten Start alle CSVs aus `data/raw/` automatisch ins `raw`-Schema. Läuft einmalig und beendet sich. | – |
| **dbt** (core 1.8) | ETL-/Transformations-Tool. Container läuft idle, dbt-Kommando per `docker compose exec` aus. | – |
| **Apache Superset 4** | BI-Tool für Dashboards. | http://localhost:8088 |

# Architektur

Pipeline im Medaillon-Stil: Roh-CSVs landen direkt in Postgres, dbt
bereitet sie schrittweise über staging → intermediate → marts auf, und
Superset liest ausschließlich aus dem Marts-Layer. Alles läuft als vier
docker-compose-Services (`postgres`, `loader`, `dbt`, `superset`).

```mermaid
flowchart LR
    csv[("data/raw/*.csv")] --> loader["loader-Container\n(pandas → Postgres,\nläuft einmalig beim Start)"]
    loader --> raw[("raw-Schema")]

    seed[("dbt/seeds/\nstatus_mapping.csv")] --> stg2["stg_status_mapping"]
    raw --> stg["stg_trade_in_orders\n(view)"]

    stg --> int["int_trade_in_orders_with_status\n(view)\nCent→Euro, Status-Join, NULLs bei Lead-Id raus"]
    stg2 --> int

    int --> fct["fct_trade_in_orders\n(table)"]
    fct --> kpis["mart_kpi_overall /\nmonatlich / nach_zustand /\nnach_lead_status\n(tables)"]

    fct --> superset["Superset-Dashboard\n(localhost:8088)"]
    kpis --> superset
```
### Lineage-Graph des mart_kpi_overall-Modells als Beispiel
![Lineagegraph](media/image3.png)

## Layer

| Layer | Materialisierung | Zweck |
|---|---|---|
| `raw` | Postgres-Tabellen | 1:1-Kopie der Quell-CSVs, geladen von `loader/load_csvs.py` |
| `staging` (`stg_*`) | view | Typumwandlung, `coalesce`-basierte Null-Behandlung ("unbekannt"/0.00), Umbenennung |
| `intermediate` (`int_*`) | view | Join des Bestellstatus gegen den `status_mapping`-Seed, Cent-→-Euro-Umrechnung, Ausfilterung fehlender Lead-Ids |
| `marts` (`fct_*`, `mart_*`) | table | Business-Logik (Funnel-Gruppierung via `status_gruppe`, Boolean-Flags, KPI-Aggregation), Single Source of Truth für Superset |

Alle Layer materialisieren im selben `analytics`-Schema; die Medaillon-
Trennung erfolgt über Ordnerstruktur (`staging/`, `intermediate/`,
`marts/`) und Namenspräfixe, nicht über separate Schemas.

## Datenqualität

Der Intermediate-Layer joint Bestellstatus-Codes per Left Join gegen den
`status_mapping`-Seed. Ein Code (`LP_S92`) taucht in den Bestelldaten auf,
fehlt aber im Seed — ein stilles `NULL` wurde erkannt und per `coalesce`
durch einen sprechenden Platzhalter (`Unbekannter Status (...)`) ersetzt,
abgesichert durch einen `not_null`-Test auf `status_beschreibung`.

## Tests aktuell

Es kommen ausschließlich dbts eingebaute generische Tests zum Einsatz, über
die Schema-Files `_staging.yml` / `_marts.yml`:

- `not_null` / `unique` auf Primärschlüsseln
- `not_null` auf Pflichtfeldern
- `accepted_values` auf Kategoriefeldern (`zustand`, `bearbeitungsstatus`, `status_gruppe`)


## Quickstart

```bash
# 1. Environment-Datei erstellen
cp .env.example .env

# 2. Stack starten (Build dauert beim allerersten Mal 2-5 Minuten)
docker compose up -d --build

# 3. Auf Superset-Bootstrap warten (~30-60 Sekunden beim ersten Start)
docker compose logs -f superset
# Abbrechen mit Ctrl+C, sobald "Listening at: http://0.0.0.0:8088" erscheint.
```

Danach erreichbar:

- **Superset**: <http://localhost:8088> (Login: `admin` / `admin`)
- **Postgres**: `postgresql://analytics:analytics@localhost:5432/analytics`
- **dbt**: `docker compose exec dbt dbt debug`

## Superset mit Postgres verbinden

Beim ersten Login muss in Superset einmalig die Analytics-Datenbank als Datenquelle hinterlegt werden:

1. Oben rechts auf **Settings → Database Connections** klicken.
2. **+ DATABASE** → als Datenbank **PostgreSQL** wählen.
3. Im Feld **SQLAlchemy URI** eintragen:

   ```
   postgresql+psycopg2://analytics:analytics@postgres:5432/analytics
   ```

4. **TEST CONNECTION** → muss „Connection looks good!" zurückgeben → **CONNECT**.
5. **Import von Dashboard** (optinal für obiges Dashboard)
    ```
    docker compose exec superset superset import-dashboards -f /app/dashboard_export.zip -u admin
    ```

>  **Wichtig:** Der Host heißt `postgres` (Name des Docker-Compose-Services), **nicht** `localhost` oder `0.0.0.0`. Aus Sicht des Superset-Containers verweist `localhost` auf den Superset-Container selbst, wo kein Postgres läuft – daher die Fehlermeldung „port is closed".
>
> User/Passwort/Datenbank entsprechen den Werten aus `.env` (Default: alle drei `analytics`).
>
> Von **außerhalb** von Docker (z. B. lokaler `psql` oder DBeaver) ist Postgres dagegen unter `localhost:5432` erreichbar.

## Daten neu laden

Wenn  eigene/zusätzliche CSVs in `data/raw/` gelegt (oder bestehende ersetzt), kann Loader erneut laufen:

```bash
docker compose up loader
```

Der Loader nutzt `if_exists='replace'`, schreibt also bestehende Tabellen neu.

## dbt-Workflow

```bash
# Verbindung testen
docker compose exec dbt dbt debug

# Models ausführen
docker compose exec dbt dbt run

# Tests laufen lassen
docker compose exec dbt dbt test

# Komplette Pipeline (seeds + models + tests)
docker compose exec dbt dbt build

# Doku-Server starten (optional, Port-Mapping ggf. nötig)
docker compose exec dbt dbt docs generate
```

## Aufräumen

```bash
# Stack stoppen, Daten bleiben erhalten
docker compose down

# Stack stoppen UND alle Daten (Postgres + Superset-Metadaten) löschen
docker compose down -v
```

## Repo-Struktur (Kurzform)

```

├── docker-compose.yml
├── data/raw/           # ← Rohdaten-CSVs landen hier
├── loader/             # CSV → Postgres Bootstrap
├── superset/           # Superset-Image + Bootstrap-Script, dashboard_export.zip
└── dbt/                # dbt-Projekt ( models/ usw. )
```