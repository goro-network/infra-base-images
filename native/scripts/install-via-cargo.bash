#!/bin/bash

set -e

source base-functions.bash
setenv_rustflags
which sccache # hack for intermittent $PATH problem in docker

cargo install "$@"
