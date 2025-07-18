FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-curl \
    php7.4-gd \
    php7.4-intl \
    php7.4-mbstring \
    php7.4-soap \
    php7.4-xml \
    php7.4-xmlrpc \
    php7.4-zip \
    wget \
    curl \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Download and install WP-CLI
RUN wget https://github.com/wp-cli/wp-cli/releases/download/v2.5.0/wp-cli-2.5.0.phar -O wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Configure PHP-FPM
RUN mkdir -p /run/php && \
    sed -i 's/listen = \/run\/php\/php7.4-fpm.sock/listen = 9000/' /etc/php/7.4/fpm/pool.d/www.conf && \
    sed -i 's/;listen.mode = 0660/listen.mode = 0660/' /etc/php/7.4/fpm/pool.d/www.conf && \
    sed -i 's/;daemonize = yes/daemonize = no/' /etc/php/7.4/fpm/php-fpm.conf

# Create wordpress directory
RUN mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html

# Copy configuration files
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf
COPY tools/setup.sh /usr/local/bin/setup.sh

RUN chmod +x /usr/local/bin/setup.sh

WORKDIR /var/www/html

EXPOSE 9000

CMD ["/usr/local/bin/setup.sh"]
