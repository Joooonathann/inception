FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Create SSL certificate
RUN mkdir -p /etc/ssl/certs && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/certs/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=FR/ST=Paris/L=Paris/O=42/OU=42/CN=jonathan.42.fr"

# Copy configuration files
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/start.sh /usr/local/bin/start.sh

RUN chmod +x /usr/local/bin/start.sh

EXPOSE 443

CMD ["/usr/local/bin/start.sh"]
