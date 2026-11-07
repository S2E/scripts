#!/bin/bash

# Copyright (c) 2017, Cyberhaven
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#
# Usage: ./run.sh path_to_binary [binary args...]
#
# The script runs as container root, which rootless Podman maps to the calling
# user, so the S2E environment that it creates belongs to that user.
#

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 path_to_binary [binary args...]"
    exit 1
fi

BINARY_PATH="$1"
shift

if [ ! -f "$BINARY_PATH" ]; then
  echo "$BINARY_PATH was not found. This path must exist inside the container."
  echo "If the binary is on your host machine, make sure that you mounted the host folder properly (-v podman option)."
  exit 1
fi

BINARY_PATH="$(readlink -f "$BINARY_PATH")"
BINARY="$(basename "$BINARY_PATH")"

# Project name doesn't have the extension
PROJECT="$(echo $BINARY | cut -f 1 -d '.')"

# S2E shared libraries are installed in a non-standard location,
# make sure the system can find them.
echo /opt/s2e/lib > /etc/ld.so.conf.d/s2e.conf
ldconfig

ROOT="$(pwd)/s2e-demo"
CURDIR="$(pwd)"

cd /s2e-env
. .venv/bin/activate

cd "$CURDIR"

if [ ! -d "$ROOT" ]; then
  s2e init -b /opt/s2e "$ROOT"
fi

cd "$ROOT"

if [ ! -d "projects/$PROJECT" ]; then
  echo "Creating new project in projects/$PROJECT"

  # Automatically download image if needed
  s2e new_project -n "$PROJECT" -d "$BINARY_PATH" "$@"
fi

echo Running $PROJECT
s2e run "$PROJECT"
