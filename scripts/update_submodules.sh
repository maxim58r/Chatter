#!/usr/bin/env bash
set -e

echo "=== Synchronizing .gitmodules with local config ==="
git submodule sync --recursive

echo "=== Updating/initializing submodules to the latest remote commits ==="
git submodule update --init --recursive --remote --merge

echo "Done!"
