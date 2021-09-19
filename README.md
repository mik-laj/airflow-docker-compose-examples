Apache Airflow Docker Compose Examples
======================================

Configuring Docker-Compose deployments requires in-house knowledge of Docker Compose. This repository contains a few examples showing some popular customization that will allow you to easily adapt the environment to your requirements.

All examples are automatically tested on CI to verify their correctness.

# Before you begin

If you want to start using Apache Airflow, you should read the guide: [Gettings started Apache Airflow with Docker](http://airflow.apache.org/docs/apache-airflow/stable/start/docker.html).

# Available examples

## Local Executor

If you only need an environment that uses only one worker, you can use [Local Executor](http://airflow.apache.org/docs/apache-airflow/2.1.4/executor/local.html).

**Apache Airflow with Local Executor with MySQL database**

```shell
curl -sSLO https://raw.githubusercontent.com/mik-laj/airflow-docker-compose-examples/compose-files/local-executor--mysql/docker-compose.yaml
```

**Apache Airflow with Local Executor with PostgreSQL database**

```shell
curl -sSLO https://raw.githubusercontent.com/mik-laj/airflow-docker-compose-examples/compose-files/local-executor--postgres/docker-compose.yaml
```

## Celery Executor

If you need an environment that is similar to what common production environments look like, then you can use [Celery Executor](http://airflow.apache.org/docs/apache-airflow/2.1.4/executor/celery.html).

**Apache Airflow with Celery Executor with MySQL database**

```shell
curl -sSLO https://raw.githubusercontent.com/mik-laj/airflow-docker-compose-examples/compose-files/celery-executor--mysql/docker-compose.yaml
```

**Apache Airflow with Celery Executor with PostgreSQL database**

```shell
curl -sSLO https://raw.githubusercontent.com/mik-laj/airflow-docker-compose-examples/compose-files/celery-executor--postgres/docker-compose.yaml
```



