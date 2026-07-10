FROM python:3.12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    "dbt-core==1.8.7" \
    "dbt-postgres==1.8.2"

WORKDIR /usr/app/dbt

# Project files are bind-mounted at runtime via docker-compose, so the
# image stays lean and any changes the candidate makes are picked up
# immediately without a rebuild.
