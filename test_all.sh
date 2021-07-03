#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
set -euo pipefail

PROJECT_SOURCES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "${PROJECT_SOURCES}"

tmp_output="$(mktemp)"
# shellcheck disable=SC2064
trap "rm -rf ${tmp_output}" EXIT
tmp_output="/tmp/test.sh"
echo "Temporary output file: ${tmp_output}"

AIRFLOW_WWW_USER_USERNAME=${_AIRFLOW_WWW_USER_USERNAME:-airflow}
AIRFLOW_WWW_USER_PASSWORD=${_AIRFLOW_WWW_USER_PASSWORD:-airflow}
DAG_ID="example_bash_operator"
DAG_RUN_ID="test_dag_run_id"

mkdir -p ./dags
curl -s 'https://raw.githubusercontent.com/apache/airflow/master/airflow/example_dags/example_bash_operator.py' -o './dags/example_bash_operator.py'

function wait_for_webserver {
    echo "Waiting for webserver"
    local countdown
    countdown="50"

    while true
    do
        set +e
        local last_check_result
        local res
        last_check_result=$(
            curl -X GET \
                --header "Content-Type: application/json" \
                -u "${AIRFLOW_WWW_USER_USERNAME}:${AIRFLOW_WWW_USER_PASSWORD}" \
                "http://localhost:8080/api/v1/health" 2>&1)
        res=$?
        set -e
        if [[ ${res} == 0 ]]; then
            echo
            break
        else
            echo -n "."
            countdown=$((countdown-1))
        fi
        if [[ ${countdown} == 0 ]]; then
            echo
            echo "ERROR! Maximum number of retries (10) reached."
            echo
            echo "Last check result:"
            echo "GET http://localhost:8080/api/v1/health"
            echo "${last_check_result}"
            echo
            exit 1
        else
            sleep 1
        fi
    done
}

function fetch_dag_state {
    curl -s -X GET \
        --header "Content-Type: application/json" \
        -u "${AIRFLOW_WWW_USER_USERNAME}:${AIRFLOW_WWW_USER_PASSWORD}" \
        "http://localhost:8080/api/v1/dags/${DAG_ID}/dagRuns/${DAG_RUN_ID}" | jq '.state' -r
}

function wait_for_dag_run {
    echo "Waiting for DAG RUN"
    dag_state="running"
    while [[ "${dag_state}" == "running" ]]; do
        dag_state=$(fetch_dag_state)
        echo "Waiting for DAG Run: dag_state=${dag_state}"
        sleep 1;
    done;
}

function test_compose_file() {
    compose_file="$1"
    compose_dir="$(dirname "${compose_file}")}"
    curl -s 'https://raw.githubusercontent.com/apache/airflow/master/airflow/example_dags/example_bash_operator.py' -o "${compose_dir}/dags/example_bash_operator.py"
    echo -e "AIRFLOW_UID=$(id -u)\nAIRFLOW_GID=0" > "${compose_dir}/.env"
    if ! COMPOSE_FILE="${compose_file}" docker-compose config &> "${tmp_output}"; then
        echo "File unparsable"
        cat "${tmp_output}"
        exit 1;
    fi
    COMPOSE_FILE="${compose_file}" docker-compose down --volumes --remove-orphans &> /dev/null || true

    if ! COMPOSE_FILE="${compose_file}" docker-compose up -d &> "${tmp_output}"; then
        echo "All services could not be started"
        cat "${tmp_output}"
        exit 1;
    fi

    COMPOSE_FILE="${compose_file}" docker-compose ps -q | xargs -n 1 -P 8 ./wait-for-container.sh

    if ! curl -s -X PATCH \
        --header "Content-Type: application/json" \
        -u "${AIRFLOW_WWW_USER_USERNAME}:${AIRFLOW_WWW_USER_PASSWORD}" \
        "http://localhost:8080/api/v1/dags/${DAG_ID}" \
        --data '{"is_paused": false}' &> "${tmp_output}"; then
        echo "DAG unpausing failed"
        cat "${tmp_output}"
        exit 1;
    fi

    if ! curl -s -X POST \
        --header "Content-Type: application/json" \
        -u "${AIRFLOW_WWW_USER_USERNAME}:${AIRFLOW_WWW_USER_PASSWORD}" \
        "http://localhost:8080/api/v1/dags/${DAG_ID}/dagRuns" \
        --data "$(jq -n '{dag_run_id: $run_id}' --arg 'run_id' "${DAG_RUN_ID}")" &> "${tmp_output}"; then
        echo "DAG Triggering failed"
        cat "${tmp_output}"
        exit 1;
    fi

    wait_for_dag_run
    dag_state=$(fetch_dag_state)

    if [[ "${dag_state}" != "success" ]]; then
        echo "Test failed"
        set -x
        echo "GET http://localhost:8080/api/v1/dags/${DAG_ID}/dagRuns/${DAG_RUN_ID}"
        curl -X GET \
            --header "Content-Type: application/json" \
            -u "${AIRFLOW_WWW_USER_USERNAME}:${AIRFLOW_WWW_USER_PASSWORD}" \
            "http://localhost:8080/api/v1/dags/${DAG_ID}/dagRuns/${DAG_RUN_ID}"
        echo "GET http://localhost:8080/api/v1/dags/${DAG_ID}/dagRuns/${DAG_RUN_ID}/taskInstances"
        curl -X GET \
            --header "Content-Type: application/json" \
            -u "${AIRFLOW_WWW_USER_USERNAME}:${AIRFLOW_WWW_USER_PASSWORD}" \
            "http://localhost:8080/api/v1/dags/${DAG_ID}/dagRuns/${DAG_RUN_ID}/taskInstances"
        exit 1
    else
        echo "Test success"
    fi

    if ! COMPOSE_FILE="${compose_file}" docker-compose down --volumes &> "${tmp_output}"; then
        echo "All services could not be stopped"
        cat "${tmp_output}"
    fi

}

find compose-files -name 'docker-compose.yaml' -type f -print0 | while IFS= read -r -d '' compose_file; do
    echo "Processing file: ${compose_file}"
    test_compose_file "$compose_file"
done

#(
#    echo "celery-executor--2.1.0--mysql.docker-compose.yaml"
#    echo "celery-executor--2.1.0--postgres.docker-compose.yaml"
#    echo "local-executor--2.1.0--mysql.docker-compose.yaml"
#    echo "local-executor--2.1.0--postgres.docker-compose.yaml"
#) | while IFS= read -r compose_file; do
#    echo "Processing file: ${compose_file}"
#    test_compose_file "$compose_file"
#done
#
#compose_file="./celery-executor--2.1.0--mysql.docker-compose.yaml"
#echo "Processing file: ${compose_file}"
#test_compose_file "$compose_file"
