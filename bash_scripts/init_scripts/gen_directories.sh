cd /usr/local/mysql/bin
for i in $(seq 1 16); do 
    sudo mkdir -p /opt/mysql/data${i}
    sudo chown -R mysql:mysql /opt/mysql/data${i}
    sudo ./mysqld --initialize-insecure \
                  --user=mysql \
                  --basedir=/usr/local/mysql \
                  --datadir=/opt/mysql/data${i} \
                  --verbose
done