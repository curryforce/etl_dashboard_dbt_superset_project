"""
Bulk-load all CSV files from /data into a Postgres schema.

Each CSV file becomes one table:
  data/raw/foo-bar.csv  ->  <RAW_SCHEMA>.foo_bar

Schema is inferred by pandas; the load uses if_exists='replace' so the
job is idempotent. The container is intended to run once at startup,
then exit.
"""
from __future__ import annotations

import logging
import os
import re
import sys
from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine, text

DATA_DIR = Path(os.environ.get("DATA_DIR", "/data"))
RAW_SCHEMA = os.environ.get("RAW_SCHEMA", "raw")
DATABASE_URL = os.environ["DATABASE_URL"]

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [loader] %(levelname)s: %(message)s",
)
log = logging.getLogger(__name__)


def sanitize(name: str) -> str:
    """Turn a filename stem into a safe SQL identifier."""
    name = name.lower()
    name = re.sub(r"[^a-z0-9_]+", "_", name)
    name = re.sub(r"_+", "_", name).strip("_")
    if not name or name[0].isdigit():
        name = f"t_{name}"
    return name


def main() -> int:
    if not DATA_DIR.is_dir():
        log.error("DATA_DIR %s does not exist", DATA_DIR)
        return 1

    csvs = sorted(DATA_DIR.glob("*.csv"))
    if not csvs:
        log.warning(
            "No CSV files found in %s. Drop your dataset there and "
            "restart the loader (docker compose up loader).",
            DATA_DIR,
        )
        return 0

    engine = create_engine(DATABASE_URL, future=True)

    with engine.begin() as conn:
        conn.execute(text(f'CREATE SCHEMA IF NOT EXISTS "{RAW_SCHEMA}"'))
        log.info("Ensured schema %s exists", RAW_SCHEMA)

    for csv_path in csvs:
        table = sanitize(csv_path.stem)
        log.info("Reading %s ...", csv_path.name)
        df = pd.read_csv(csv_path, low_memory=False)
        log.info("  -> %d rows, %d cols", len(df), len(df.columns))
        df.to_sql(
            table,
            engine,
            schema=RAW_SCHEMA,
            if_exists="replace",
            index=False,
            chunksize=10_000,
            method="multi",
        )
        log.info("  -> wrote %s.%s", RAW_SCHEMA, table)

    log.info("Loader finished: %d table(s) loaded.", len(csvs))
    return 0


if __name__ == "__main__":
    sys.exit(main())
