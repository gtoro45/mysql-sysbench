# ==== Delete any existing .cnf files ====
sudo rm -rf /etc/conf*.cnf

# ==== Parse command line arguments ====
for arg in "$@"; do
    case $arg in
        --instances=*) NUM_INSTANCES="${arg#*=}" ;; # Number of MySQL instances
        *) echo "Unknown parameter passed: $arg"; exit 1 ;;
    esac
done
mem_capacity_per_node=128
mem_capacity_per_instance=$(echo "$mem_capacity_per_node / $NUM_INSTANCES" | bc -l)

# Conditional logic with floating point comparison
if (( $(echo "$mem_capacity_per_instance <= 6" | bc -l) )); then
    pool_size_gb=$(echo "$mem_capacity_per_instance - 1.5" | bc -l)
else
    pool_size_gb=$(echo "$mem_capacity_per_instance * 0.75" | bc -l)
fi

# Convert GB to bytes and trim .000000
pool_size_bytes=$(echo "$pool_size_gb * 1024 * 1024 * 1024" | bc -l | cut -d'.' -f1)
echo $pool_size_bytes

# make the .cnf files
BASE_PORT=3306
for i in $(seq 1 $NUM_INSTANCES); do
    cat <<EOF > /etc/conf${i}.cnf
[mysqld]
port=$((BASE_PORT + i - 1))
basedir=/usr/local/mysql
datadir=/opt/mysql/data${i}
socket=/tmp/mysql${i}.sock
max_prepared_stmt_count = 655350
max_connections = 10000
# innodb_log_file_size = 1048576000
innodb_io_capacity = 10000
innodb_io_capacity_max = 10000
innodb_buffer_pool_load_at_startup = OFF
innodb_buffer_pool_dump_at_shutdown = OFF
innodb_flush_method = O_DIRECT
innodb_change_buffering = 0
table_open_cache = 20000
skip_log_bin = 1
skip_name_resolve = 1
skip_replica_start = 1
performance_schema = OFF
innodb_buffer_pool_size = ${pool_size_bytes}
EOF
done


# [mysqld]
# port=3307
# datadir=/opt/mysql/instance1
# socket=/tmp/mysql1.sock