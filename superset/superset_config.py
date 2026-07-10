"""Minimal Superset configuration

The SECRET_KEY is sourced from the environment. Everything else uses
Superset defaults (SQLite metadata DB inside the container's
SUPERSET_HOME volume) which is intentionak.
"""
import os

SECRET_KEY = os.environ.get(
    "SUPERSET_SECRET_KEY", "please-change-me-to-a-long-random-string"
)

# Allow embedding the dashboard 
FEATURE_FLAGS = {
    "DASHBOARD_NATIVE_FILTERS": True,
    "DASHBOARD_CROSS_FILTERS": True,
}

# CSV upload is helpful for ad-hoc exploration during the task.
CSV_EXPORT = {"encoding": "utf-8"}
