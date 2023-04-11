#!/bin/bash

GH_AUTH_TOKEN=${GH_AUTH_TOKEN}
GH_ORGANIZATION=${GH_ORGANIZATION}
GH_RUNNER_GROUP=${GH_RUNNER_GROUP}
GH_RUNNER_LABELS=${GH_RUNNER_LABELS}
GH_RUNNER_NAME=${GH_RUNNER_NAME}

function get_github_runner_registration_token() {
    curl -sX POST https://api.github.com/orgs/${GH_ORGANIZATION}/actions/runners/registration-token \
        -H "Authorization: Bearer ${GH_AUTH_TOKEN}" | jq .token --raw-output
}

./config.sh \
    --disableupdate \
    --replace \
    --unattended \
    --labels ${GH_RUNNER_LABELS} \
    --name ${GH_RUNNER_NAME} \
    --runnergroup ${GH_RUNNER_GROUP} \
    --token $(get_github_runner_registration_token) \
    --url "https://github.com/${GH_ORGANIZATION}"

cleanup_runner() {
    echo "Removing runner..."
    ./config.sh \
        remove \
        --token $(get_github_runner_registration_token)
}

trap 'cleanup_runner; exit 130' SIGINT
trap 'cleanup_runner; exit 143' SIGTERM

./run.sh & wait $!
