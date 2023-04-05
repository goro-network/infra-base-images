#!/bin/bash

RUNNER_GROUP=${RUNNER_GROUP}
RUNNER_LABELS=${RUNNER_LABELS}
RUNNER_NAME=${RUNNER_NAME}
RUNNER_ORG=${RUNNER_ORG}
RUNNER_TOKEN=${RUNNER_TOKEN}

./config.sh \
    --disableupdate \
    --replace \
    --unattended \
    --labels ${RUNNER_LABELS} \
    --name ${RUNNER_NAME} \
    --runnergroup ${RUNNER_GROUP} \
    --token ${RUNNER_TOKEN} \
    --url "https://github.com/${RUNNER_ORG}"

cleanup_runner() {
    echo "Removing runner..."
    ./config.sh \
        remove \
        --token ${RUNNER_REG}
}

trap 'cleanup_runner; exit 130' SIGINT
trap 'cleanup_runner; exit 143' SIGTERM

./run.sh & wait $!
