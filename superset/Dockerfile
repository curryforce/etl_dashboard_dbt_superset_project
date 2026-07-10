FROM apache/superset:4.0.2

USER root

# psycopg2-binary so Superset can connect to the analytics Postgres.
RUN pip install --no-cache-dir psycopg2-binary==2.9.9

COPY superset_config.py /app/pythonpath/superset_config.py
COPY docker-init.sh /app/docker-init.sh
COPY dashboard_export.zip /app/dashboard_export.zip
RUN chmod +x /app/docker-init.sh

ENV SUPERSET_CONFIG_PATH=/app/pythonpath/superset_config.py
ENV PYTHONPATH=/app/pythonpath:${PYTHONPATH}

USER superset

ENTRYPOINT ["/app/docker-init.sh"]
