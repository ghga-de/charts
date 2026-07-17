#!/usr/bin/env bash
set -euo pipefail

# Python dependencies used by scripts/*.py and src/create_charts.py
# (kept in sync with .github/workflows/library-update.yml and library-release.yml)
pip install --user semver "ruamel.yaml==0.18.12" requests
