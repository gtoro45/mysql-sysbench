#!/bin/bash
# This script is ran on the x86 (Client) Machine

# ==== User defined variables ====
# Parse CLI arguments
for arg in "$@"; do
    case $arg in
        --host=*) HOST_ADDRESS="${arg#*=}" ;;       # MySQL server host address
        --user=*) HOST_USER="${arg#*=}" ;;          # Server username
        --password=*) HOST_PASSWORD="${arg#*=}" ;;  # Server password
        --cpus=*) NUM_CPUs="${arg#*=}" ;;           # Number of vCPUs running
        --instances=*) NUM_INSTANCES="${arg#*=}" ;; # Number of MySQL instances 
        --threads=*) THREADS="${arg#*=}" ;;         # Number of threads to benchmark
        --time=*) TIME="${arg#*=}" ;;               # Sysbench test runtime limit
        --skip=*) skip_debug="${arg#*=}" ;;         # Debugging flag to skip the main loop
        *) echo "Unknown parameter passed: $arg"; exit 1 ;;
    esac
done


# ==== Conditional Constants ====
if [[ "$NUM_INSTANCES" -eq 1 ]]; then
    TABLES=40
    SCALE=400
else
    TABLES=10
    SCALE=100
fi

PREPARE_THREADS=$(( TABLES < NUM_CPUs ? TABLES : NUM_CPUs ))

if [[ "$NUM_INSTANCES" -eq 1 ]]; then   # ensure max of 4 threads for 1 instance on 16 Cores
    PREPARE_THREADS=4
fi

# ==== Other Constants ====
BASE_PORT=3306


# ==== Run TPCC Tests ====
echo "Running TPCC Tests on $NUM_INSTANCES instances ($NUM_CPUs CPU(s) per instance) with tables=$TABLES and scale=$SCALE"

# Identify the correct .lua sysbench file
LUA_FILE="/home/ubuntu/workloads/mysql-sysbench/sysbench-tpcc/tpcc.lua"

# Setup TPCC Tests
start_time=$(date +%s)
echo "==== Preparing Data in Each Instance ===="
for i in $(seq 1 $NUM_INSTANCES); do
    echo "Instance ${i} Initializing..."  
    sysbench $LUA_FILE \
            --tables=$TABLES \
            --scale=$SCALE \
            --threads=$PREPARE_THREADS \
            --time=$TIME \
            --mysql-host=$HOST_ADDRESS \
            --mysql-db=testdb \
            --mysql-user=root \
            --mysql-password='ubuntu' \
            --mysql-port=$((BASE_PORT + i - 1)) \
            --report-interval=10 \
            --percentile=85\
            prepare > /dev/null &
done

# Wait before running
wait
end_time=$(date +%s)
runtime=$((end_time - start_time))
echo "Setup elapsed time: ${runtime} seconds"
printf "\n"

# Run TPCC Tests
echo "==== Running Benchmarks ===="
for i in $(seq 1 $NUM_INSTANCES); do
    OUT_PATH="/home/ubuntu/workloads/MySQL/raw/TPCC/${NUM_CPUs}vCPUs_${NUM_INSTANCES}_instances/${THREADS}_threads/out"
    ERR_PATH="/home/ubuntu/workloads/MySQL/raw/TPCC/${NUM_CPUs}vCPUs_${NUM_INSTANCES}_instances/${THREADS}_threads/err"
    mkdir -p $OUT_PATH
    mkdir -p $ERR_PATH
    sysbench $LUA_FILE \
            --tables=$TABLES \
            --scale=$SCALE \
            --threads=$THREADS \
            --time=$TIME \
            --mysql-host=$HOST_ADDRESS \
            --mysql-db=testdb \
            --mysql-user=root \
            --mysql-password='ubuntu' \
            --mysql-port=$((BASE_PORT + i - 1)) \
            --report-interval=10 \
            --percentile=85\
            run > "${OUT_PATH}/inst_${i}_TPCC.out" 2> "${ERR_PATH}/inst_${i}_TPCC.err" &
    echo "Instance ${i} data can be found in:"
    echo "$OUT_PATH"
    echo "$ERR_PATH"
done

# Wait before cleanup
wait
printf "\n"


# Cleanup TPCC Tests
echo "==== Cleaning up Databases ===="
for i in $(seq 1 $NUM_INSTANCES); do
    sysbench $LUA_FILE \
            --tables=$TABLES \
            --mysql-host=$HOST_ADDRESS \
            --mysql-db=testdb \
            --mysql-user=root \
            --mysql-password='ubuntu' \
            --mysql-port=$((BASE_PORT + i - 1)) \
            cleanup
done
printf "\n"

# Reset MySQL instances to relieve memory via an external script
echo "==== Resetting MySQL Instances ===="
sudo bash /home/ubuntu/workloads/MySQL/bash_scripts/benchmarking/reset_instances.sh > /dev/null 

# ADDED --> fixes tasket affinity issues (no longer running hardcoded script on server machine)
echo "[SERVER] Starting $NUM_INSTANCES MySQL instances "
cat ./init_scripts/run_instances.sh | sshpass -p "$HOST_PASSWORD" ssh -q -o StrictHostKeyChecking=no "$HOST_USER@$HOST_ADDRESS" \
                "sudo bash -s -- \
                --instances=${NUM_INSTANCES} \
                --cpus-per-instance=${NUM_CPUs}" | sed 's/^/    /'

printf "\n"
sleep 10