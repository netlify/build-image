#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

docker pull netlify/build:trusty
export NETLIFY_IMAGE_TAG=trusty
exec "$DIR/start-image.sh" $@
