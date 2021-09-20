#!/usr/bin/env python

import sys
from argparse import ArgumentParser
from pathlib import Path

import httpx
import jinja2
import jsonschema
import semver
import yaml

if __name__ not in ("__main__", "__mp_main__"):
    raise SystemExit(
        "This file is intended to be executed as an executable program. You cannot use it as a module."
        f"To run this script, run the ./{__file__} command."
    )

TEMPLATE_DIR = Path(__file__).resolve().parent
COMPOSE_SPEC_URL = (
    "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"
)


def fail(message: str):
    raise Exception(message)


def render_jinja_template(template_name: str, **kwargs) -> str:
    """Render Jinja template"""
    template_loader = jinja2.FileSystemLoader(searchpath=TEMPLATE_DIR)
    template_env = jinja2.Environment(
        loader=template_loader,
        undefined=jinja2.StrictUndefined,
        lstrip_blocks=True,
        trim_blocks=True,
    )
    template: jinja2.Template = template_env.get_template(template_name)
    content: str = template.render(**kwargs, fail=fail)
    return content


def validate_docker_compose(text_content: str) -> None:
    content = yaml.safe_load(text_content)
    response = httpx.get(COMPOSE_SPEC_URL)
    response.raise_for_status()
    schema = response.json()
    jsonschema.validate(content, schema)


def render_docker_compose(*, airflow_version: str, executor: str, db_backend: str) -> str:
    text_content = render_jinja_template(
        'docker-compose.yaml.jinja2',
        airflow_version=airflow_version,
        executor=executor,
        db_backend=db_backend,
    )
    try:
        validate_docker_compose(text_content)
    except:
        print(text_content, file=sys.stderr)
        raise
    return text_content


def get_parser() -> ArgumentParser:
    parser = ArgumentParser(
        prog=__file__,
    )
    parser.add_argument('--executor', choices=('CeleryExecutor', 'LocalExecutor'), required=True)
    parser.add_argument('--airflow-version', type=semver.VersionInfo.parse, required=True)
    parser.add_argument('--db-backend', choices=("postgres", "mysql"), default="postgres")

    return parser


def main() -> None:
    parser = get_parser()
    args = parser.parse_args()
    if args.airflow_version < semver.VersionInfo.parse("2.1.0"):
        print(
            f"Unsupported Airflow version [{args.airflow_version}]. At least version 2.1.0 is required.",
            file=sys.stderr,
        )
        sys.exit(1)
    print(
        render_docker_compose(
            airflow_version=str(args.airflow_version), executor=args.executor, db_backend=args.db_backend
        )
    )


main()
