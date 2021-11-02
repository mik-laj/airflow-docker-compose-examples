#!/usr/bin/env python3

import re
import subprocess
import sys
from pathlib import Path

MARKER_START = '<!-- AIRFLOW_VERSION_START -->'
MARKER_END = '<!-- AIRFLOW_VERSION_END -->'

REPO_ROOT = Path(__file__).resolve().parent.parent

README_FILE = REPO_ROOT / 'README.md'

airflow_version = (REPO_ROOT / "requirements-airflow.txt").read_text().split("==")[1].strip()

readme_content = README_FILE.read_text()
new_content = re.sub(
    f"{re.escape(MARKER_START)}.+?{re.escape(MARKER_END)}",
    f"{MARKER_START}{airflow_version}{MARKER_END}",
    readme_content,
    flags=re.MULTILINE | re.DOTALL,
)
new_content = new_content.strip() + "\n"

if readme_content != new_content:
    with open(README_FILE, "w") as readme_file_handle:
        readme_file_handle.write(new_content)
    print(f"File updated: {README_FILE}")
    sys.exit(1)

print("No changes needed")
