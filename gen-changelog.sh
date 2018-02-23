#!/bin/bash

exec auto-changelog -u -t keepachangelog -l false --ignore-commit-pattern "^v?[0-9\.]+$" --starting-commit 9d2e26a "$@"
