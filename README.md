# Apache Airflow Docker Compose Examples

Configuring Docker-Compose deployments requires in-house knowledge of Docker Compose. This repository contains a few examples showing some popular customization that will allow you to easily adapt the environment to your requirements If none of the examples meet your expectations, you can also use a script that generates files based on a template, just like Helm, to generate files for Kubernetes.

All pre-generated examples are automatically tested on CI to verify their correctness. The published files are compatible with Airflow 2.2.0. Files for older versions can be created using [a generator](#generate-your-docker-composeyaml-file).

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Before you begin](#before-you-begin)
- [Available examples](#available-examples)
- [Generate your `docker-compose.yaml` file](#generate-your-docker-composeyaml-file)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Before you begin

If you want to start using Apache Airflow, you should read the guide: [Gettings started Apache Airflow with Docker](http://airflow.apache.org/docs/apache-airflow/stable/start/docker.html).

## Available examples

For convenience, we generated some examples and tested some `docker-compose.yaml` files.

### Local Executor

If you only need an environment that uses only one worker, you can use [Local Executor](http://airflow.apache.org/docs/apache-airflow/2.1.4/executor/local.html).

**Apache Airflow with Local Executor with PostgreSQL database (recommended) **

```shell
curl -sSLO https://raw.githubusercontent.com/mik-laj/airflow-docker-compose-examples/compose-files/local-executor--postgres/docker-compose.yaml
```

**Apache Airflow with Local Executor with MySQL database**

```shell
curl -sSLO https://raw.githubusercontent.com/mik-laj/airflow-docker-compose-examples/compose-files/local-executor--mysql/docker-compose.yaml
```

**Apache Airflow with Local Executor with Microsoft SQL database**

```shell
curl -sSLO https://raw.githubusercontent.com/mik-laj/airflow-docker-compose-examples/compose-files/local-executor--mssql/docker-compose.yaml
```

### Celery Executor

If you need an environment that is similar to what common production environments look like, then you can use [Celery Executor](http://airflow.apache.org/docs/apache-airflow/2.1.4/executor/celery.html).

**Apache Airflow with Celery Executor with PostgreSQL database**

```shell
curl -sSLO https://raw.githubusercontent.com/mik-laj/airflow-docker-compose-examples/compose-files/celery-executor--postgres/docker-compose.yaml
```

**Apache Airflow with Celery Executor with MySQL database**

```shell
curl -sSLO https://raw.githubusercontent.com/mik-laj/airflow-docker-compose-examples/compose-files/celery-executor--mysql/docker-compose.yaml
```

**Apache Airflow with Celery Executor with Microsoft SQL database**

```shell
curl -sSLO https://raw.githubusercontent.com/mik-laj/airflow-docker-compose-examples/compose-files/celery-executor--mssql/docker-compose.yaml
```

## Generate your `docker-compose.yaml` file

All examples in this repository generated from one Jinja2 template - [`./docker-compose.yaml.jinja2`](./docker-compose.yaml.jinja2). If you need to generate an example in a less typical configuration, you can do so with the [`./render.py`](./render.py) script.

Supported Airflow version: 2.1.0 and newer.
Only latest version (2.2.0) is tested on CI and published in this repo.

<!-- USAGE_START -->
```
usage: ./render.py [-h] --executor {CeleryExecutor,LocalExecutor}
                   --airflow-version AIRFLOW_VERSION
                   [--db-backend {postgres,mysql,mssql}]

optional arguments:
  -h, --help            show this help message and exit
  --executor {CeleryExecutor,LocalExecutor}
  --airflow-version AIRFLOW_VERSION
  --db-backend {postgres,mysql,mssql}

```
<!-- USAGE_END -->
