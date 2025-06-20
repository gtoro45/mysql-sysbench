# ==== Parse command line arguments ====
for arg in "$@"; do
    case $arg in
        --instances=*) NUM_INSTANCES="${arg#*=}" ;; # Number of MySQL instances
        *) echo "Unknown parameter passed: $arg"; exit 1 ;;
    esac
done

mem_capacity_per_instance=

cd /etc/


# [mysqld]
# port=3307
# datadir=/opt/mysql/instance1
# socket=/tmp/mysql1.sock