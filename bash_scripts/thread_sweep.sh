# script to sweep through thread counts on different MySQL instances
#!/bin/bash
# This script is run on the x86 (Client) Machine

# ==== User defined variables ====
$HOST_ADDRESS=""
TIME=180
BASE_PORT=3306

# ==== Test Parameters ====
LUA_FILE="" # read only lua file for sysbench

# ==== Read Only Tests ====
# 1 CPU --> 16 instances
NUM_CPUs=1
NUM_INSTANCES=16
PREPARE_THREADS=1

echo "==== Preparing Data in Each Instance ===="
for i in $(seq 1 $NUM_INSTANCES); do
    echo "Instance ${i} Initializing..."  
    sysbench $LUA_FILE \
            --tables=10 \
            --table-size=10000000 \
            --threads=$PREPARE_THREADS \
            --time=$TIME \
            --mysql-host=$HOST_ADDRESS \
            --mysql-db=testdb \
            --mysql-user=root \
            --mysql-password='ubuntu' \
            --mysql-port=$((BASE_PORT + i - 1)) \
            --report-interval=10 \
            --percentile=95\
            prepare > /dev/null &
done

for THREADS in 1 2 4 8; do # 1:1, 1:2, 1:4, 1:8 
    # TODO
done


# 4 CPUs --> 4 instances
NUM_CPUs=4
NUM_INSTANCES=4
PREPARE_THREADS=4

echo "==== Preparing Data in Each Instance ===="
for i in $(seq 1 $NUM_INSTANCES); do
    echo "Instance ${i} Initializing..."  
    sysbench $LUA_FILE \
            --tables=10 \
            --table-size=10000000 \
            --threads=$PREPARE_THREADS \
            --time=$TIME \
            --mysql-host=$HOST_ADDRESS \
            --mysql-db=testdb \
            --mysql-user=root \
            --mysql-password='ubuntu' \
            --mysql-port=$((BASE_PORT + i - 1)) \
            --report-interval=10 \
            --percentile=95\
            prepare > /dev/null &
done


for THREADS in 4 8 16 32; do # 1:1, 1:2, 1:4, 1:8 
    # TODO
done

# 16 CPUs --> 1 instance
NUM_CPUs=16
NUM_INSTANCES=1
PREPARE_THREADS=8

echo "==== Preparing Data in Each Instance ===="
for i in $(seq 1 $NUM_INSTANCES); do
    echo "Instance ${i} Initializing..."  
    sysbench $LUA_FILE \
            --tables=40 \
            --table-size=40000000 \
            --threads=$PREPARE_THREADS \
            --time=$TIME \
            --mysql-host=$HOST_ADDRESS \
            --mysql-db=testdb \
            --mysql-user=root \
            --mysql-password='ubuntu' \
            --mysql-port=$((BASE_PORT + i - 1)) \
            --report-interval=10 \
            --percentile=95\
            prepare > /dev/null &
done


for THREADS in 16 32 64 128; do # 1:1, 1:2, 1:4, 1:8 
    # TODO
done

