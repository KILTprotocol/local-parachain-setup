#!/bin/bash
set -x
set -e

# READ ENV FILE
set -o allexport
source .env$1
set +o allexport

# PROJECT_NAME = <user_id>-<current_directory_name>
PROJECT_NAME=$USER-${PWD##*/}$1

# TEARDOWN AND DELETE
docker compose -p $PROJECT_NAME down -v