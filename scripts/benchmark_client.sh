#!/usr/bin/env bash
set -e

COLOR_RED='\033[1;31m'
COLOR_END='\033[0m'

zig/zig build -Drelease-safe
mv zig-out/bin/tigerbeetle .

function onerror {
    if [ "$?" == "0" ]; then
        rm benchmark-client.log
    else
        echo -e "${COLOR_RED}"
        echo "Error running benchmark, here are more details (from benchmark-client.log):"
        echo -e "${COLOR_END}"
        cat benchmark-client.log
    fi

    for I in 0
    do
        echo "Stopping replica $I..."
    done
    kill %1
}
trap onerror EXIT

CLUSTER_ID="--cluster-id=0a5ca1ab1ebee11e"
REPLICA_ADDRESSES="--replica-addresses=3001"

for I in 0
do
    echo "Starting replica $I..."
    ./tigerbeetle $CLUSTER_ID $REPLICA_ADDRESSES --replica-index=$I > benchmark-client.log 2>&1 &
done

# Wait for replicas to start, listen and connect:
sleep 1

echo ""
echo "Benchmarking client..."
zig/zig run -OReleaseSafe src/benchmark_client.zig
echo ""
