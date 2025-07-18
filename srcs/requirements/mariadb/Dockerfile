FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Copy configuration
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/setup.sh /usr/local/bin/setup.sh

RUN chmod +x /usr/local/bin/setup.sh

# Create mysql directory
RUN mkdir -p /var/lib/mysql && \
    chown -R mysql:mysql /var/lib/mysql

EXPOSE 3306

CMD ["/usr/local/bin/setup.sh"]
