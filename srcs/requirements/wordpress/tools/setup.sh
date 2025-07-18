#!/bin/bash

# Wait for MariaDB to be ready
while ! mysqladmin ping -h mariadb -u root -p"$(cat /run/secrets/db_root_password)" --silent; do
    echo "Waiting for MariaDB..."
    sleep 5
done

# Change to wordpress directory
cd /var/www/html

# Download WordPress if not already present
if [ ! -f wp-config.php ]; then
    echo "Downloading WordPress..."
    wp core download --allow-root
    
    # Create wp-config.php
    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$(cat /run/secrets/db_password)" \
        --dbhost="mariadb" \
        --allow-root
    
    # Install WordPress
    wp core install \
        --url="https://$DOMAIN_NAME" \
        --title="Inception WordPress" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --allow-root
    
    # Create additional user
    wp user create \
        "$WP_USER" \
        "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD" \
        --role=author \
        --allow-root
fi

# Set proper permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Start PHP-FPM
php-fpm7.4 --nodaemonize
