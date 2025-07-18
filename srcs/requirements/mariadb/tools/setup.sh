#!/bin/bash

# Read secrets
DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

# Create directory and set permissions
mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld
chown -R mysql:mysql /var/lib/mysql

# Initialize database if WordPress database doesn't exist
if [ ! -d "/var/lib/mysql/$MYSQL_DATABASE" ]; then
    echo "Initializing MariaDB..."
    
    echo "Starting MariaDB temporarily to configure it..."
    
    # Start MariaDB temporarily to configure it
    mysqld_safe --user=mysql --datadir=/var/lib/mysql &
    MYSQL_PID=$!
    
    # Wait for MariaDB to start
    until mysqladmin ping --silent; do
        echo "Waiting for MariaDB to start..."
        sleep 2
    done
    
    echo "Configuring MariaDB..."
    
    # Create databases and users
    mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASSWORD';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;
CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';
FLUSH PRIVILEGES;
EOF
    
    echo "MariaDB configured successfully"
    
    # Stop temporary MariaDB
    kill $MYSQL_PID
    wait $MYSQL_PID
fi

echo "Starting MariaDB in foreground..."
# Start MariaDB in foreground
exec mysqld_safe --user=mysql --datadir=/var/lib/mysql
