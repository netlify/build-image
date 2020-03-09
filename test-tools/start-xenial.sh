#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

docker pull netlify/build:xenial
export NETLIFY_IMAGE_TAG=xenial
exec "$DIR/start-image.sh" $@
