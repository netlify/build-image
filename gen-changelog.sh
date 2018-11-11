#!/bin/bash

exec auto-changelog -u -t keepachangelog -l false --starting-commit 9d2e26a "$@"
