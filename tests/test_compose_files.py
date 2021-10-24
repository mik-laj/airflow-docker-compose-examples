import contextlib
import os
import shlex
import subprocess
import tempfile
import urllib
from contextlib import ExitStack
from pathlib import Path
from pprint import pprint
from shutil import copyfile
from time import sleep
from typing import Dict

import httpx
import pytest

COMPOSE_FILES_DIR = p = Path(__file__).resolve().parent.parent / "compose-files"
COMPOSE_FILES = list(p.glob("**/docker-compose.yaml"))
COMPOSE_FILES = [d for d in COMPOSE_FILES if 'celery' in str(d) and 'postgres' in str(d)]

AIRFLOW_WWW_USER_USERNAME = os.environ.get("_AIRFLOW_WWW_USER_USERNAME", "airflow")
AIRFLOW_WWW_USER_PASSWORD = os.environ.get("_AIRFLOW_WWW_USER_PASSWORD", "airflow")
DAG_ID = "example_bash_operator"
DAG_RUN_ID = "test_dag_run_id"


def api_request(method, path, base_url="http://localhost:8080/api/v1", **kwargs) -> Dict:
    response = httpx.request(
        method=method,
        url=f"{base_url}/{path}",
        auth=(AIRFLOW_WWW_USER_USERNAME, AIRFLOW_WWW_USER_PASSWORD),
        headers={"Content-Type": "application/json"},
        **kwargs,
    )
    response.raise_for_status()
    return response.json()


def wait_for_dag_state(dag_id, dag_run_id):
    # Wait 30 seconds
    for _ in range(30):
        dag_state = api_request("GET", f"dags/{dag_id}/dagRuns/{dag_run_id}").get("state")
        print(f"Waiting for DAG Run: dag_state={dag_state}")
        sleep(1)
        if dag_state in ("success", "failed"):
            break


@contextlib.contextmanager
def tmp_chdir(path):
    current_cwd = os.getcwd()
    try:
        os.chdir(path)
        yield current_cwd
    finally:
        os.chdir(current_cwd)


def run_cmd(args, **kwargs):
    if isinstance(args, str):
        print(f"$ {args}")
    elif isinstance(args, list):
        cmd = " ".join(shlex.quote(a) for a in args)
        print(f"$ {cmd}")
    else:
        raise Exception(f"Unexpected argument: {args} (type: {type(args)})")

    kwargs.setdefault("check", True)
    return subprocess.run(args=args, **kwargs)


@pytest.mark.parametrize("compose_file", COMPOSE_FILES)
def test_valid_components(compose_file):
    with tempfile.TemporaryDirectory() as tmp_dir, tmp_chdir(tmp_dir) as orig_cwd:
        os.mkdir(f"{tmp_dir}/dags")
        os.mkdir(f"{tmp_dir}/logs")
        os.mkdir(f"{tmp_dir}/plugins")
        with open(".env", "w+") as env_file:
            uid = subprocess.check_output(["id", "-u"]).decode()
            env_file.write(f"AIRFLOW_UID={uid}\n")
        run_cmd("find . -type d | xargs -n 1 -t ls -lah", shell=True)
        copyfile(compose_file, f"{tmp_dir}/docker-compose.yaml")
        run_cmd(
            "curl -s 'https://raw.githubusercontent.com/apache/airflow/master/airflow/example_dags/example_bash_operator.py' -o dags/example_bash_operator.py",
            shell=True,
        )
        run_cmd(["docker-compose", "config"])
        run_cmd(["docker-compose", "down", "--volumes", "--remove-orphans"])
        try:
            p_events = None
            with ExitStack() as exit_stack:
                # p_events = exit_stack..enter_context(subprocess.Popen(["docker-compose", "events"]));
                try:
                    run_cmd(["docker-compose", "up", "-d"])
                    # Wait until all containers are healthy. Unfortunately, docker-compose does not have such
                    # a built-in command yet. It only has the ability to wait for containers that have dependencies,
                    # but the last last containers remain without health control on startup.
                    run_cmd(
                        f"docker-compose ps -q | xargs -n 1 -P 8 -r {orig_cwd}/wait-for-container.sh", shell=True
                    )
                    api_request("PATCH", path=f"dags/{DAG_ID}", json={"is_paused": False})
                    api_request("POST", path=f"dags/{DAG_ID}/dagRuns", json={"dag_run_id": DAG_RUN_ID})
                    wait_for_dag_state(dag_id=DAG_ID, dag_run_id=DAG_RUN_ID)
                    dag_state = api_request("GET", f"dags/{DAG_ID}/dagRuns/{DAG_RUN_ID}").get("state")
                    assert dag_state == "success"
                except:
                    print(f"HTTP: GET dags/{DAG_ID}/dagRuns/{DAG_RUN_ID}")
                    pprint(api_request("GET", f"dags/{DAG_ID}/dagRuns/{DAG_RUN_ID}"))
                    print(f"HTTP: GET dags/{DAG_ID}/dagRuns/{DAG_RUN_ID}/taskInstances")
                    pprint(api_request("GET", f"dags/{DAG_ID}/dagRuns/{DAG_RUN_ID}/taskInstances"))
                    if p_events:
                        p_events.terminate()
                        p_events.communicate()
                    raise
        except:
            run_cmd(["docker-compose", "ps"])
            run_cmd(["docker-compose", "logs", "airflow-triggerer"])
            raise
        finally:
            run_cmd(["docker-compose", "down", "--volumes"])
