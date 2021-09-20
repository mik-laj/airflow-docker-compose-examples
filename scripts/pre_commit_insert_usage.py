#!/usr/bin/env python3

import re
import subprocess
import sys
from pathlib import Path

MARKER_START = '<!-- USAGE_START -->'
MARKER_END = '<!-- USAGE_END -->'

REPO_ROOT = Path(__file__).resolve().parent.parent

TEMPLATE_FILE = REPO_ROOT / 'docker-compose.yaml.jinja2'
README_FILE = REPO_ROOT / 'README.md'

help_output = subprocess.check_output(['./render.py', '--help'], timeout=5).decode()

readme_content = README_FILE.read_text()
new_content = re.sub(
    f"{re.escape(MARKER_START)}\n.+?{re.escape(MARKER_END)}", f"{MARKER_START}\n```\n{help_output}\n```\n{MARKER_END}\n", readme_content, flags=re.MULTILINE| re.DOTALL)

if readme_content != new_content:
    with open(README_FILE, "w") as readme_file_handle:
        readme_file_handle.write(new_content)
    print(f"File updated: {README_FILE}")
    sys.exit(1)

print("No changes needed")
