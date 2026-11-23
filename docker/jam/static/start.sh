#!/bin/bash
echo "Starting App"
cd "$(dirname "$0")/jam/serve" || exit
exec node dist/index.js
