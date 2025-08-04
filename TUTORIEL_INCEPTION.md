# 🐳 TUTORIEL INCEPTION COMPLET - Déploiement Docker Avancé

## 📝 **Introduction**

Ce tutoriel détaillé vous guide dans la création complète du projet **Inception** de 42 School. Nous allons construire une infrastructure web complète utilisant Docker, avec NGINX comme reverse proxy SSL, WordPress avec PHP-FPM, et MariaDB comme base de données. Chaque composant sera expliqué en détail avec des exemples pratiques et des conseils de dépannage.

> ⚠️ **Important** : Ce guide couvre uniquement la partie obligatoire (pas de bonus) mais avec un niveau de détail approfondi pour bien comprendre chaque aspect technique.

## 📋 **Table des matières**

1. [Contexte et objectifs](#contexte)
2. [Prérequis et préparation](#prerequis)
3. [Architecture technique détaillée](#architecture)
4. [Structure complète du projet](#structure)
5. [Concepts Docker fondamentaux](#concepts)
6. [Configuration détaillée des services](#services)
7. [Déploiement étape par étape](#deploiement)
8. [Scripts et automatisation](#scripts)
9. [Sécurité et bonnes pratiques](#securite)
10. [Tests et validation complète](#tests)
11. [Monitoring et logs](#monitoring)
12. [Dépannage avancé](#depannage)
13. [Optimisations et performances](#optimisations)

---

## 🎯 **Contexte et objectifs** {#contexte}

### **Le projet Inception : Pourquoi ?**

Le projet Inception de 42 School simule un environnement de production réel où vous devez :
- **Containeriser** une application web complète
- **Orchestrer** plusieurs services interdépendants
- **Sécuriser** les communications avec SSL/TLS
- **Persister** les données de manière fiable
- **Automatiser** le déploiement et la maintenance

### **Infrastructure cible :**

```
🌐 Internet (Port 443 HTTPS)
    ↓
🔒 NGINX (Reverse Proxy + SSL Termination)
    ↓ 
🐘 WordPress + PHP-FPM (Application Web)
    ↓
🗄️ MariaDB (Base de données)
```

### **Contraintes techniques strictes :**

#### **🔧 Services obligatoires :**
- ✅ **NGINX** : Serveur web avec TLS v1.2/1.3 UNIQUEMENT (port 443)
- ✅ **WordPress** : CMS avec PHP-FPM (PAS d'Apache/Nginx intégré)
- ✅ **MariaDB** : Base de données (PAS MySQL)

#### **🐳 Contraintes Docker :**
- ✅ **Images de base** : Debian Bullseye UNIQUEMENT
- ✅ **Construction** : Images personnalisées (PAS d'images ready-made)
- ✅ **Orchestration** : Docker Compose
- ✅ **Réseau** : Réseau Docker dédié
- ✅ **Volumes** : Persistance des données
- ✅ **Secrets** : Gestion sécurisée des mots de passe

#### **🔐 Sécurité :**
- ✅ **SSL/TLS** : Certificats auto-signés
- ✅ **Isolation** : Containers séparés
- ✅ **Secrets** : Mots de passe via Docker secrets
- ✅ **Permissions** : Utilisateurs non-root quand possible

---

## 🛠️ **Prérequis et préparation** {#prerequis}

### **Environnement requis :**

```bash
# Vérifier Docker et Docker Compose
docker --version          # Docker 20.10+
docker-compose --version  # Docker Compose 1.29+

# Vérifier les permissions
groups $USER | grep docker  # L'utilisateur doit être dans le groupe docker

# Vérifier l'espace disque (minimum 5GB)
df -h /
```

### **Configuration système :**

```bash
# Ajouter l'utilisateur au groupe docker (si nécessaire)
sudo usermod -aG docker $USER
newgrp docker

# Configurer le hostname (important pour SSL)
echo "127.0.0.1 jalbiser.42.fr" | sudo tee -a /etc/hosts

# Arrêter les services web conflictuels
sudo systemctl stop apache2 nginx 2>/dev/null || true
sudo fuser -k 443/tcp 2>/dev/null || true
```

### **Création de l'environnement de travail :**

```bash
# Créer le répertoire principal
mkdir -p ~/inception && cd ~/inception

# Vérifier les permissions
ls -la ~/inception
# Doit afficher : drwxr-xr-x utilisateur utilisateur
```

---

## 🏗️ **Architecture technique détaillée** {#architecture}

### **Vue d'ensemble de l'infrastructure :**

```
┌─────────────────────────────────────────────────────────────────┐
│                        HOST SYSTEM (Linux)                      │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    DOCKER ENGINE                          │  │
│  │                                                          │  │
│  │  ┌─────────────────────────────────────────────────────┐ │  │
│  │  │              INCEPTION NETWORK                      │ │  │
│  │  │                (Bridge Network)                     │ │  │
│  │  │                                                     │ │  │
│  │  │  ┌──────────┐    ┌──────────┐    ┌──────────┐     │ │  │
│  │  │  │  NGINX   │    │WORDPRESS │    │ MARIADB  │     │ │  │
│  │  │  │Container │    │Container │    │Container │     │ │  │
│  │  │  │          │    │          │    │          │     │ │  │
│  │  │  │Port 443  │◄───│Port 9000 │◄───│Port 3306 │     │ │  │
│  │  │  │(HTTPS)   │    │(PHP-FPM) │    │(MySQL)   │     │ │  │
│  │  │  └────┬─────┘    └────┬─────┘    └────┬─────┘     │ │  │
│  │  │       │               │               │           │ │  │
│  │  │       └───────────────┼───────────────┘           │ │  │
│  │  │                       │                           │ │  │
│  │  └───────────────────────┼───────────────────────────┘ │  │
│  │                          │                             │  │
│  └──────────────────────────┼─────────────────────────────┘  │
│                             │                                │
│  ┌─────────────────────────┴─────────────────────────────┐   │
│  │                   VOLUMES PERSISTANTS                  │   │
│  │                                                       │   │
│  │  /home/jalbiser/data/wordpress/ ◄──► wp_data          │   │
│  │  /home/jalbiser/data/mysql/     ◄──► db_data          │   │
│  │                                                       │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
        ▲
        │ Port 443 (HTTPS)
┌───────┴───────┐
│   INTERNET    │
│   CLIENT      │
└───────────────┘
```

### **Flux de données détaillé :**

1. **Client HTTPS** (navigateur) → **Port 443** → **NGINX Container**
2. **NGINX** (SSL Termination) → **Port 9000** → **WordPress Container**
3. **WordPress** (PHP-FPM) → **Port 3306** → **MariaDB Container**
4. **MariaDB** (Base de données) → **Réponse** → **WordPress**
5. **WordPress** (HTML généré) → **Réponse** → **NGINX**
6. **NGINX** (SSL Encryption) → **HTTPS** → **Client**

### **Réseau Docker détaillé :**

```yaml
# Réseau personnalisé "inception"
networks:
  inception:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1
```

**Adressage IP automatique :**
- `nginx`: 172.20.0.2
- `wordpress`: 172.20.0.3  
- `mariadb`: 172.20.0.4

### **Volumes et persistance :**

```yaml
volumes:
  wp_data:
    driver: local
    driver_opts:
      type: none      # Bind mount (lien direct vers système hôte)
      o: bind
      device: /home/jalbiser/data/wordpress
  
  db_data:
    driver: local
    driver_opts:
      type: none      # Bind mount pour persistance garantie
      o: bind
      device: /home/jalbiser/data/mysql
```

**Avantages des bind mounts :**
- Données accessibles depuis l'hôte
- Backup facilité
- Persistance garantie même après suppression des containers

---

## 📁 **Structure complète du projet** {#structure}

```
inception/                                    # Répertoire racine du projet
├── Makefile                                  # Automatisation des tâches
├── TUTORIEL_INCEPTION.md                     # Documentation complète
│
├── secrets/                                  # 🔐 Mots de passe (Docker Secrets)
│   ├── credentials.txt                       # Utilisateurs WordPress (user:pass)
│   ├── db_password.txt                       # Mot de passe utilisateur DB
│   └── db_root_password.txt                  # Mot de passe root MariaDB
│
└── srcs/                                     # Code source principal
    ├── docker-compose.yml                    # 🐳 Orchestration des services
    ├── .env                                  # Variables d'environnement
    │
    └── requirements/                         # Configurations par service
        │
        ├── nginx/                            # 🌐 Serveur web + SSL
        │   ├── Dockerfile                    # Construction image NGINX
        │   ├── conf/
        │   │   └── nginx.conf                # Configuration serveur NGINX
        │   └── tools/
        │       └── start.sh                  # Script démarrage NGINX
        │
        ├── wordpress/                        # 🐘 Application WordPress
        │   ├── Dockerfile                    # Construction image WordPress
        │   ├── conf/
        │   │   └── www.conf                  # Configuration PHP-FPM
        │   └── tools/
        │       └── setup.sh                  # Installation auto WordPress
        │
        └── mariadb/                          # 🗄️ Base de données
            ├── Dockerfile                    # Construction image MariaDB
            ├── conf/
            │   └── 50-server.cnf             # Configuration serveur DB
            └── tools/
                └── setup.sh                  # Initialisation DB + users
```

### **Détail des fichiers critiques :**

#### **🔐 Fichiers secrets (sensibles) :**
```bash
# secrets/db_password.txt
wppassword123

# secrets/db_root_password.txt  
rootsecurepass456

# secrets/credentials.txt
jdoe:adminpass123
regularuser:userpass123
```

#### **⚙️ Variables d'environnement (.env) :**
```bash
# Domaine principal
DOMAIN_NAME=jalbiser.42.fr

# Configuration MariaDB
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=wppassword123
MYSQL_ROOT_PASSWORD=rootsecurepass456

# Configuration WordPress
WP_ADMIN_USER=jdoe
WP_ADMIN_PASSWORD=adminpass123
WP_ADMIN_EMAIL=admin@jalbiser.42.fr
WP_USER=regularuser
WP_USER_PASSWORD=userpass123
WP_USER_EMAIL=user@jalbiser.42.fr

# Chemins de données
MYSQL_DATA_PATH=/home/jalbiser/data/mysql
WP_DATA_PATH=/home/jalbiser/data/wordpress
```

---

## 🐳 **Concepts Docker fondamentaux** {#concepts}

### **Docker vs Machines Virtuelles :**

```
┌─────────────────────────┐  ┌─────────────────────────┐
│    MACHINE VIRTUELLE    │  │        DOCKER           │
├─────────────────────────┤  ├─────────────────────────┤
│   App 1  │   App 2      │  │   App 1  │   App 2      │
├──────────┼──────────────┤  ├──────────┼──────────────┤
│   OS 1   │   OS 2       │  │ Runtime 1│ Runtime 2    │
├──────────┴──────────────┤  ├──────────┴──────────────┤
│     HYPERVISEUR         │  │    DOCKER ENGINE        │
├─────────────────────────┤  ├─────────────────────────┤
│      OS HÔTE            │  │      OS HÔTE            │
├─────────────────────────┤  ├─────────────────────────┤
│      HARDWARE           │  │      HARDWARE           │
└─────────────────────────┘  └─────────────────────────┘
```

**Avantages Docker :**
- ✅ **Léger** : Partage le kernel de l'hôte
- ✅ **Rapide** : Démarrage en secondes
- ✅ **Portable** : Identique dev/prod
- ✅ **Scalable** : Orchestration native

### **Concepts clés utilisés :**

#### **1. Images Docker :**
```bash
# Construction d'une image
docker build -t nginx:custom ./requirements/nginx/

# Layers (couches) d'une image
docker history nginx:custom
```

#### **2. Containers :**
```bash
# Lancement d'un container
docker run -d --name nginx nginx:custom

# Inspection d'un container  
docker inspect nginx
```

#### **3. Volumes :**
```bash
# Volume nommé
docker volume create wp_data

# Bind mount
docker run -v /host/path:/container/path nginx:custom
```

#### **4. Réseaux :**
```bash
# Création réseau personnalisé
docker network create inception

# Communication inter-containers
# nginx peut contacter wordpress via "http://wordpress:9000"
```

#### **5. Docker Compose :**
```yaml
# Orchestration multi-containers
version: '3.8'
services:
  nginx:
    build: ./nginx
    depends_on:
      - wordpress
```

### **Sécurité Docker :**

#### **🔒 Isolation des containers :**
- **PID namespace** : Chaque container voit ses propres processus
- **Network namespace** : Isolation réseau
- **Mount namespace** : Système de fichiers isolé
- **User namespace** : Mapping d'utilisateurs

#### **🛡️ Bonnes pratiques :**
```dockerfile
# ❌ MAUVAIS : utilisateur root
USER root

# ✅ BON : utilisateur dédié
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

# ✅ BON : réduire la surface d'attaque
RUN apt-get update && apt-get install -y needed-package \
    && rm -rf /var/lib/apt/lists/*

# ✅ BON : multi-stage builds
FROM debian:bullseye as builder
RUN build-dependencies...

FROM debian:bullseye
COPY --from=builder /app /app
```

---

## ⚙️ **Configuration détaillée des services** {#services}

### **🌐 NGINX - Reverse Proxy + SSL Termination**

#### **Rôle et responsabilités :**
- **Point d'entrée HTTPS** : Seul service exposé vers l'extérieur
- **SSL Termination** : Chiffrement/déchiffrement TLS
- **Reverse Proxy** : Redirection vers WordPress
- **Load Balancing** : Répartition de charge (extensible)
- **Sécurité** : Filtrage des requêtes, headers sécurisés

#### **📋 Dockerfile NGINX complet :**

```dockerfile
# srcs/requirements/nginx/Dockerfile
FROM debian:bullseye

# Installation des packages nécessaires
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Création des répertoires SSL
RUN mkdir -p /etc/ssl/certs /etc/ssl/private

# Génération du certificat SSL auto-signé
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=FR/ST=Ile-de-France/L=Paris/O=42School/OU=Student/CN=jalbiser.42.fr/emailAddress=admin@jalbiser.42.fr"

# Génération des paramètres Diffie-Hellman (sécurité renforcée)
RUN openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

# Création de l'utilisateur nginx (sécurité)
RUN groupadd -r nginx && useradd -r -g nginx nginx

# Configuration des permissions
RUN chown -R nginx:nginx /var/log/nginx \
    && chown -R nginx:nginx /var/lib/nginx \
    && chmod 600 /etc/ssl/private/nginx-selfsigned.key \
    && chmod 644 /etc/ssl/certs/nginx-selfsigned.crt

# Copie de la configuration personnalisée
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/start.sh /usr/local/bin/start.sh

# Permissions d'exécution
RUN chmod +x /usr/local/bin/start.sh

# Exposition du port HTTPS
EXPOSE 443

# Vérification de la configuration au build
RUN nginx -t

# Commande de démarrage
CMD ["/usr/local/bin/start.sh"]
```

#### **📝 Configuration NGINX complète :**

```nginx
# srcs/requirements/nginx/conf/nginx.conf

# Configuration globale
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

# Optimisation des connexions
events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    # Types MIME
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Format des logs
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    # Optimisations de performance
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 64M;

    # Sécurité - Masquer la version NGINX
    server_tokens off;

    # Configuration SSL/TLS sécurisée
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_dhparam /etc/ssl/certs/dhparam.pem;

    # Headers de sécurité
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";

    # Configuration du serveur principal
    server {
        listen 443 ssl http2;
        server_name jalbiser.42.fr;
        root /var/www/html;
        index index.php index.html index.htm;

        # Certificats SSL
        ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
        ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

        # Logs spécifiques au vhost
        access_log /var/log/nginx/jalbiser.42.fr.access.log;
        error_log /var/log/nginx/jalbiser.42.fr.error.log;

        # Gestion des fichiers statiques
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            try_files $uri =404;
        }

        # Configuration PHP-FPM pour WordPress
        location ~ \.php$ {
            try_files $uri =404;
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass wordpress:9000;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param PATH_INFO $fastcgi_path_info;
            
            # Optimisations FastCGI
            fastcgi_buffer_size 128k;
            fastcgi_buffers 4 256k;
            fastcgi_busy_buffers_size 256k;
            fastcgi_temp_file_write_size 256k;
            fastcgi_read_timeout 240;
        }

        # Gestion des permaliens WordPress
        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }

        # Sécurité - Bloquer l'accès aux fichiers sensibles
        location ~ /\. {
            deny all;
            access_log off;
            log_not_found off;
        }

        location ~* /(?:uploads|files)/.*\.php$ {
            deny all;
        }

        location ~ ^/(wp-admin|wp-includes)/ {
            location ~ \.php$ {
                try_files $uri =404;
                fastcgi_pass wordpress:9000;
                fastcgi_index index.php;
                include fastcgi_params;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            }
        }

        # Page d'erreur personnalisée
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root /var/www/html;
        }
    }

    # Redirection HTTP vers HTTPS (si nécessaire)
    server {
        listen 80;
        server_name jalbiser.42.fr;
        return 301 https://$server_name$request_uri;
    }
}
```

#### **🚀 Script de démarrage NGINX :**

```bash
#!/bin/bash
# srcs/requirements/nginx/tools/start.sh

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}[NGINX] Démarrage du serveur NGINX...${NC}"

# Vérification de la configuration
echo -e "${YELLOW}[NGINX] Vérification de la configuration...${NC}"
nginx -t
if [ $? -ne 0 ]; then
    echo -e "${RED}[NGINX] Erreur dans la configuration NGINX${NC}"
    exit 1
fi

# Vérification des certificats SSL
if [ ! -f /etc/ssl/certs/nginx-selfsigned.crt ] || [ ! -f /etc/ssl/private/nginx-selfsigned.key ]; then
    echo -e "${RED}[NGINX] Certificats SSL manquants${NC}"
    exit 1
fi

# Vérification de la connectivité vers WordPress
echo -e "${YELLOW}[NGINX] Attente de WordPress...${NC}"
while ! nc -z wordpress 9000; do
    echo -e "${YELLOW}[NGINX] WordPress non disponible, attente...${NC}"
    sleep 2
done
echo -e "${GREEN}[NGINX] WordPress détecté, démarrage...${NC}"

# Création des répertoires de logs si nécessaires
mkdir -p /var/log/nginx

# Démarrage de NGINX en foreground
echo -e "${GREEN}[NGINX] Serveur NGINX démarré sur le port 443${NC}"
exec nginx -g 'daemon off;'
```

### **🐘 WordPress - Application Web avec PHP-FPM**

#### **Rôle et responsabilités :**
- **CMS WordPress** : Interface d'administration et front-end
- **PHP-FPM** : Gestionnaire de processus PHP (FastCGI)
- **WP-CLI** : Installation et configuration automatisées
- **Connexion DB** : Communication avec MariaDB
- **Gestion utilisateurs** : Création automatique des comptes

#### **📋 Dockerfile WordPress complet :**

```dockerfile
# srcs/requirements/wordpress/Dockerfile
FROM debian:bullseye

# Variables d'environnement pour éviter les prompts interactifs
ENV DEBIAN_FRONTEND=noninteractive

# Installation de PHP et extensions WordPress
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
    php7.4-bcmath \
    php7.4-imagick \
    php7.4-json \
    wget \
    curl \
    mariadb-client \
    netcat \
    unzip \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Installation de WP-CLI (outil officiel WordPress)
RUN wget https://github.com/wp-cli/wp-cli/releases/download/v2.5.0/wp-cli-2.5.0.phar -O wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Vérification de l'installation WP-CLI
RUN wp --info

# Configuration de PHP-FPM
RUN mkdir -p /run/php \
    && sed -i 's/listen = \/run\/php\/php7.4-fpm.sock/listen = 9000/' /etc/php/7.4/fpm/pool.d/www.conf \
    && sed -i 's/;listen.mode = 0660/listen.mode = 0660/' /etc/php/7.4/fpm/pool.d/www.conf \
    && sed -i 's/;daemonize = yes/daemonize = no/' /etc/php/7.4/fpm/php-fpm.conf

# Optimisations PHP pour WordPress
RUN sed -i 's/memory_limit = 128M/memory_limit = 256M/' /etc/php/7.4/fpm/php.ini \
    && sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 64M/' /etc/php/7.4/fpm/php.ini \
    && sed -i 's/post_max_size = 8M/post_max_size = 64M/' /etc/php/7.4/fpm/php.ini \
    && sed -i 's/max_execution_time = 30/max_execution_time = 300/' /etc/php/7.4/fpm/php.ini

# Création du répertoire WordPress
RUN mkdir -p /var/www/html \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Copie des configurations
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf
COPY tools/setup.sh /usr/local/bin/setup.sh

# Permissions d'exécution
RUN chmod +x /usr/local/bin/setup.sh

# Définir le répertoire de travail
WORKDIR /var/www/html

# Port PHP-FPM
EXPOSE 9000

# Commande de démarrage
CMD ["/usr/local/bin/setup.sh"]
```

#### **📝 Configuration PHP-FPM :**

```ini
; srcs/requirements/wordpress/conf/www.conf

[www]
user = www-data
group = www-data

listen = 9000
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

; Pool de processus
pm = dynamic
pm.max_children = 20
pm.start_servers = 4
pm.min_spare_servers = 2
pm.max_spare_servers = 6
pm.max_requests = 500

; Optimisations
pm.process_idle_timeout = 10s
request_terminate_timeout = 300s
rlimit_files = 1024
rlimit_core = 0

; Logs
catch_workers_output = yes
php_admin_value[error_log] = /var/log/php-fpm.log
php_admin_flag[log_errors] = on

; Sécurité
php_admin_value[open_basedir] = /var/www/html:/tmp
php_admin_value[disable_functions] = exec,passthru,shell_exec,system,proc_open,popen

; Variables d'environnement
env[HOSTNAME] = $HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
```

#### **🚀 Script d'installation WordPress :**

```bash
#!/bin/bash
# srcs/requirements/wordpress/tools/setup.sh

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[WORDPRESS] Initialisation de WordPress...${NC}"

# Lire les secrets Docker
if [ -f /run/secrets/db_password ]; then
    DB_PASSWORD=$(cat /run/secrets/db_password)
    echo -e "${GREEN}[WORDPRESS] Secret db_password lu avec succès${NC}"
else
    echo -e "${RED}[WORDPRESS] Erreur: impossible de lire db_password${NC}"
    exit 1
fi

if [ -f /run/secrets/db_root_password ]; then
    DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
    echo -e "${GREEN}[WORDPRESS] Secret db_root_password lu avec succès${NC}"
else
    echo -e "${RED}[WORDPRESS] Erreur: impossible de lire db_root_password${NC}"
    exit 1
fi

# Attendre que MariaDB soit disponible
echo -e "${YELLOW}[WORDPRESS] Attente de MariaDB...${NC}"
while ! mysqladmin ping -h mariadb -u "$MYSQL_USER" -p"$DB_PASSWORD" --silent; do
    echo -e "${YELLOW}[WORDPRESS] MariaDB non disponible, attente...${NC}"
    sleep 3
done
echo -e "${GREEN}[WORDPRESS] MariaDB est disponible${NC}"

# Vérifier si WordPress est déjà installé
if [ ! -f wp-config.php ]; then
    echo -e "${YELLOW}[WORDPRESS] Téléchargement de WordPress...${NC}"
    
    # Télécharger WordPress avec WP-CLI
    wp core download --allow-root --version=latest --locale=fr_FR
    
    echo -e "${YELLOW}[WORDPRESS] Configuration de WordPress...${NC}"
    
    # Créer le fichier de configuration
    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbhost="mariadb:3306" \
        --allow-root
    
    # Ajouter des configurations de sécurité WordPress
    {
        echo ""
        echo "/* Configurations de sécurité personnalisées */"
        echo "define('WP_DEBUG', false);"
        echo "define('WP_DEBUG_LOG', false);"
        echo "define('WP_DEBUG_DISPLAY', false);"
        echo "define('SCRIPT_DEBUG', false);"
        echo "define('DISALLOW_FILE_EDIT', true);"
        echo "define('DISALLOW_FILE_MODS', true);"
        echo "define('FORCE_SSL_ADMIN', true);"
        echo "define('WP_CACHE', true);"
        echo ""
        echo "/* Limitations de révisions */"
        echo "define('WP_POST_REVISIONS', 3);"
        echo "define('AUTOSAVE_INTERVAL', 300);"
        echo ""
        echo "/* Configuration de la corbeille */"
        echo "define('EMPTY_TRASH_DAYS', 7);"
    } >> wp-config.php
    
    # Vérifier la connexion à la base de données
    if ! wp db check --allow-root; then
        echo -e "${RED}[WORDPRESS] Erreur de connexion à la base de données${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}[WORDPRESS] Installation de WordPress...${NC}"
    
    # Installer WordPress
    wp core install \
        --url="https://$DOMAIN_NAME" \
        --title="Site WordPress Inception" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --allow-root
    
    echo -e "${YELLOW}[WORDPRESS] Création de l'utilisateur supplémentaire...${NC}"
    
    # Créer un utilisateur supplémentaire
    wp user create \
        "$WP_USER" \
        "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD" \
        --role=author \
        --allow-root
    
    echo -e "${YELLOW}[WORDPRESS] Configuration des thèmes et plugins...${NC}"
    
    # Activer un thème moderne
    wp theme install twentytwentyfour --activate --allow-root
    
    # Supprimer les plugins et thèmes par défaut non nécessaires
    wp plugin delete hello --allow-root 2>/dev/null || true
    wp theme delete twentytwentyone twentytwentytwo twentytwentythree --allow-root 2>/dev/null || true
    
    # Créer du contenu de démonstration
    wp post create --post_type=page --post_title="Accueil" --post_content="Bienvenue sur votre site WordPress Inception !" --post_status=publish --allow-root
    wp option update start_of_week 1 --allow-root
    wp option update timezone_string "Europe/Paris" --allow-root
    
    echo -e "${GREEN}[WORDPRESS] WordPress installé et configuré avec succès${NC}"
    
    # Afficher les informations de connexion
    echo -e "${BLUE}[WORDPRESS] Informations de connexion:${NC}"
    echo -e "${BLUE}  - URL: https://$DOMAIN_NAME${NC}"
    echo -e "${BLUE}  - Admin: $WP_ADMIN_USER${NC}"
    echo -e "${BLUE}  - Utilisateur: $WP_USER${NC}"
else
    echo -e "${GREEN}[WORDPRESS] WordPress déjà installé${NC}"
fi

# Correction des permissions
echo -e "${YELLOW}[WORDPRESS] Correction des permissions...${NC}"
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;
chmod 600 wp-config.php

# Démarrage de PHP-FPM
echo -e "${GREEN}[WORDPRESS] Démarrage de PHP-FPM...${NC}"
exec php-fpm7.4 -F
```

### **🗄️ MariaDB - Base de données haute performance**

#### **Rôle et responsabilités :**
- **Stockage persistant** : Données WordPress (posts, utilisateurs, configurations)
- **Gestion utilisateurs** : Comptes MySQL sécurisés
- **Performances** : Optimisations pour WordPress
- **Sécurité** : Isolation réseau, authentification forte
- **Backup** : Données persistantes via volumes

#### **📋 Dockerfile MariaDB complet :**

```dockerfile
# srcs/requirements/mariadb/Dockerfile
FROM debian:bullseye

# Variables d'environnement
ENV DEBIAN_FRONTEND=noninteractive

# Installation de MariaDB
RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    netcat \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Création des répertoires nécessaires
RUN mkdir -p /var/lib/mysql /var/run/mysqld \
    && chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
    && chmod 755 /var/run/mysqld

# Copie des configurations
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/setup.sh /usr/local/bin/setup.sh

# Permissions d'exécution
RUN chmod +x /usr/local/bin/setup.sh

# Port MySQL/MariaDB
EXPOSE 3306

# Commande de démarrage
CMD ["/usr/local/bin/setup.sh"]
```

#### **📝 Configuration MariaDB :**

```ini
# srcs/requirements/mariadb/conf/50-server.cnf

[mysqld]
# Configuration de base
user = mysql
pid-file = /var/run/mysqld/mysqld.pid
socket = /var/run/mysqld/mysqld.sock
port = 3306
basedir = /usr
datadir = /var/lib/mysql
tmpdir = /tmp
lc-messages-dir = /usr/share/mysql

# Réseau et sécurité
bind-address = 0.0.0.0
skip-networking = false
skip-name-resolve = true

# Optimisations performances
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M
innodb_file_per_table = 1
innodb_flush_method = O_DIRECT

# Cache et buffers
key_buffer_size = 128M
max_allowed_packet = 64M
thread_stack = 192K
thread_cache_size = 8
myisam_recover_options = BACKUP
query_cache_limit = 1M
query_cache_size = 16M

# Logs
log_error = /var/log/mysql/error.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# Connexions
max_connections = 200
connect_timeout = 60
wait_timeout = 600
max_allowed_packet = 64M

# Sécurité
sql_mode = STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION

# UTF8 par défaut
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4

[client]
default-character-set = utf8mb4
```

#### **🚀 Script d'initialisation MariaDB :**

```bash
#!/bin/bash
# srcs/requirements/mariadb/tools/setup.sh

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[MARIADB] Initialisation de MariaDB...${NC}"

# Lire les secrets Docker
if [ -f /run/secrets/db_password ]; then
    DB_PASSWORD=$(cat /run/secrets/db_password)
    echo -e "${GREEN}[MARIADB] Secret db_password lu avec succès${NC}"
else
    echo -e "${RED}[MARIADB] Erreur: impossible de lire db_password${NC}"
    exit 1
fi

if [ -f /run/secrets/db_root_password ]; then
    DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
    echo -e "${GREEN}[MARIADB] Secret db_root_password lu avec succès${NC}"
else
    echo -e "${RED}[MARIADB] Erreur: impossible de lire db_root_password${NC}"
    exit 1
fi

# Créer les répertoires et définir les permissions
mkdir -p /var/run/mysqld /var/log/mysql
chown -R mysql:mysql /var/run/mysqld /var/lib/mysql /var/log/mysql
chmod 755 /var/run/mysqld

# Vérifier si la base de données WordPress existe déjà
if [ ! -d "/var/lib/mysql/$MYSQL_DATABASE" ]; then
    echo -e "${YELLOW}[MARIADB] Première installation - Configuration de la base de données...${NC}"
    
    # Démarrer MariaDB temporairement pour la configuration
    echo -e "${YELLOW}[MARIADB] Démarrage temporaire de MariaDB...${NC}"
    mysqld_safe --user=mysql --datadir=/var/lib/mysql &
    MYSQL_PID=$!
    
    # Attendre que MariaDB soit prêt
    echo -e "${YELLOW}[MARIADB] Attente du démarrage de MariaDB...${NC}"
    until mysqladmin ping --silent; do
        echo -e "${YELLOW}[MARIADB] MariaDB en cours de démarrage...${NC}"
        sleep 2
    done
    
    echo -e "${GREEN}[MARIADB] MariaDB démarré, configuration en cours...${NC}"
    
    # Configuration sécurisée de MariaDB
    mysql -u root <<EOF
-- Sécurisation de l'installation
ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASSWORD';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Création de la base de données WordPress
CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Création de l'utilisateur WordPress avec permissions appropriées
CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';

-- Optimisations pour WordPress
SET GLOBAL innodb_buffer_pool_size = 268435456;  -- 256MB
SET GLOBAL query_cache_size = 16777216;          -- 16MB
SET GLOBAL max_allowed_packet = 67108864;        -- 64MB

-- Application des changements
FLUSH PRIVILEGES;
EOF
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[MARIADB] Configuration de la base de données réussie${NC}"
        
        # Vérification de la création de l'utilisateur
        echo -e "${YELLOW}[MARIADB] Vérification de l'utilisateur WordPress...${NC}"
        mysql -u root -p"$DB_ROOT_PASSWORD" -e "SELECT User, Host FROM mysql.user WHERE User='$MYSQL_USER';"
        
        # Vérification de la base de données
        echo -e "${YELLOW}[MARIADB] Vérification de la base de données...${NC}"
        mysql -u root -p"$DB_ROOT_PASSWORD" -e "SHOW DATABASES;" | grep "$MYSQL_DATABASE"
        
        # Test de connexion avec l'utilisateur WordPress
        echo -e "${YELLOW}[MARIADB] Test de connexion utilisateur WordPress...${NC}"
        mysql -u "$MYSQL_USER" -p"$DB_PASSWORD" -e "USE $MYSQL_DATABASE; SELECT 'Connection successful' as Status;"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[MARIADB] Test de connexion WordPress réussi${NC}"
        else
            echo -e "${RED}[MARIADB] Échec du test de connexion WordPress${NC}"
            exit 1
        fi
        
    else
        echo -e "${RED}[MARIADB] Erreur lors de la configuration de la base de données${NC}"
        exit 1
    fi
    
    # Arrêter MariaDB temporaire
    echo -e "${YELLOW}[MARIADB] Arrêt de l'instance temporaire...${NC}"
    kill $MYSQL_PID
    wait $MYSQL_PID 2>/dev/null
    
    echo -e "${GREEN}[MARIADB] Configuration initiale terminée${NC}"
else
    echo -e "${GREEN}[MARIADB] Base de données déjà configurée${NC}"
fi

# Démarrage final de MariaDB en mode production
echo -e "${GREEN}[MARIADB] Démarrage de MariaDB en mode production...${NC}"
echo -e "${BLUE}[MARIADB] Base de données: $MYSQL_DATABASE${NC}"
echo -e "${BLUE}[MARIADB] Utilisateur: $MYSQL_USER${NC}"
echo -e "${BLUE}[MARIADB] Port: 3306${NC}"

# Démarrage en foreground
exec mysqld_safe --user=mysql --datadir=/var/lib/mysql
```

---

## 🚀 **Déploiement étape par étape** {#deploiement}

### **Phase 1 : Préparation de l'environnement**

#### **1.1 - Création de la structure du projet :**

```bash
# Créer le répertoire principal
mkdir -p ~/inception && cd ~/inception

# Créer la structure complète
mkdir -p secrets
mkdir -p srcs/requirements/{nginx,wordpress,mariadb}/{conf,tools}

# Vérifier la structure
tree . || find . -type d | sort
```

#### **1.2 - Configuration des secrets Docker :**

```bash
# Secrets MariaDB
echo "wppassword123" > secrets/db_password.txt
echo "rootsecurepass456" > secrets/db_root_password.txt

# Utilisateurs WordPress
cat > secrets/credentials.txt << 'EOF'
jdoe:adminpass123
regularuser:userpass123
EOF

# Vérifier les permissions (important pour la sécurité)
chmod 600 secrets/*
ls -la secrets/
```

#### **1.3 - Variables d'environnement :**

```bash
cat > srcs/.env << 'EOF'
# Domaine principal
DOMAIN_NAME=jalbiser.42.fr

# Configuration MariaDB
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=wppassword123
MYSQL_ROOT_PASSWORD=rootsecurepass456

# Configuration WordPress
WP_ADMIN_USER=jdoe
WP_ADMIN_PASSWORD=adminpass123
WP_ADMIN_EMAIL=admin@jalbiser.42.fr
WP_USER=regularuser
WP_USER_PASSWORD=userpass123
WP_USER_EMAIL=user@jalbiser.42.fr

# Chemins de données
MYSQL_DATA_PATH=/home/jalbiser/data/mysql
WP_DATA_PATH=/home/jalbiser/data/wordpress
EOF
```

### **Phase 2 : Docker Compose - Orchestration**

#### **2.1 - Configuration Docker Compose complète :**

```yaml
# srcs/docker-compose.yml
version: '3.8'

services:
  # Service NGINX - Point d'entrée HTTPS
  nginx:
    build:
      context: ./requirements/nginx
      dockerfile: Dockerfile
    container_name: nginx
    image: nginx:custom
    ports:
      - "443:443"
    volumes:
      - wp_data:/var/www/html:ro  # Lecture seule pour sécurité
    depends_on:
      - wordpress
    networks:
      - inception
    restart: unless-stopped
    env_file:
      - .env
    healthcheck:
      test: ["CMD", "curl", "-f", "-k", "https://localhost:443"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # Service WordPress - Application web
  wordpress:
    build:
      context: ./requirements/wordpress
      dockerfile: Dockerfile
    container_name: wordpress
    image: wordpress:custom
    volumes:
      - wp_data:/var/www/html
    depends_on:
      - mariadb
    networks:
      - inception
    restart: unless-stopped
    env_file:
      - .env
    secrets:
      - db_password
      - db_root_password
    healthcheck:
      test: ["CMD", "nc", "-z", "localhost", "9000"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  # Service MariaDB - Base de données
  mariadb:
    build:
      context: ./requirements/mariadb
      dockerfile: Dockerfile
    container_name: mariadb
    image: mariadb:custom
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - inception
    restart: unless-stopped
    env_file:
      - .env
    secrets:
      - db_password
      - db_root_password
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s

# Configuration des volumes persistants
volumes:
  wp_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/jalbiser/data/wordpress

  db_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/jalbiser/data/mysql

# Réseau isolé pour les services
networks:
  inception:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.name: "inception0"
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1

# Secrets Docker pour la sécurité
secrets:
  db_password:
    file: ../secrets/db_password.txt
  db_root_password:
    file: ../secrets/db_root_password.txt
```

### **Phase 3 : Construction et scripts**

#### **3.1 - Makefile d'automatisation avancé :**

```makefile
# Makefile
.PHONY: all up down clean fclean re logs status help

# Variables
COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = /home/jalbiser/data
USER = jalbiser

# Couleurs pour les messages
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m

# Cible par défaut
all: up

# Aide
help:
	@echo "$(GREEN)Commandes disponibles :$(NC)"
	@echo "  $(YELLOW)make up$(NC)      - Démarrer l'infrastructure"
	@echo "  $(YELLOW)make down$(NC)    - Arrêter les services"
	@echo "  $(YELLOW)make clean$(NC)   - Nettoyer images et volumes"
	@echo "  $(YELLOW)make fclean$(NC)  - Nettoyage complet + données"
	@echo "  $(YELLOW)make re$(NC)      - Reconstruire complètement"
	@echo "  $(YELLOW)make logs$(NC)    - Afficher les logs en temps réel"
	@echo "  $(YELLOW)make status$(NC)  - Statut des services"

# Démarrage de l'infrastructure
up: create-dirs
	@echo "$(GREEN)🚀 Démarrage de l'infrastructure Inception...$(NC)"
	docker-compose -f $(COMPOSE_FILE) up -d --build
	@echo "$(GREEN)✅ Infrastructure démarrée avec succès$(NC)"
	@echo "$(YELLOW)🌐 Site accessible sur: https://jalbiser.42.fr:443$(NC)"

# Création des répertoires de données
create-dirs:
	@echo "$(YELLOW)📁 Création des répertoires de données...$(NC)"
	sudo mkdir -p $(DATA_DIR)/wordpress
	sudo mkdir -p $(DATA_DIR)/mysql
	sudo chown -R $(USER):$(USER) $(DATA_DIR)
	@echo "$(GREEN)✅ Répertoires créés$(NC)"

# Arrêt des services
down:
	@echo "$(YELLOW)🛑 Arrêt des services...$(NC)"
	docker-compose -f $(COMPOSE_FILE) down
	@echo "$(GREEN)✅ Services arrêtés$(NC)"

# Nettoyage des images et volumes Docker
clean:
	@echo "$(YELLOW)🧹 Nettoyage des ressources Docker...$(NC)"
	docker-compose -f $(COMPOSE_FILE) down --rmi all --volumes
	docker system prune -f
	@echo "$(GREEN)✅ Nettoyage terminé$(NC)"

# Nettoyage complet incluant les données
fclean: clean
	@echo "$(RED)🗑️  Suppression complète des données...$(NC)"
	sudo rm -rf $(DATA_DIR)/wordpress/*
	sudo rm -rf $(DATA_DIR)/mysql/*
	docker system prune -af --volumes
	@echo "$(GREEN)✅ Nettoyage complet terminé$(NC)"

# Reconstruction complète
re: fclean up

# Affichage des logs en temps réel
logs:
	@echo "$(YELLOW)📋 Logs en temps réel (Ctrl+C pour quitter)...$(NC)"
	docker-compose -f $(COMPOSE_FILE) logs -f

# Statut des services
status:
	@echo "$(GREEN)📊 Statut des services :$(NC)"
	@docker-compose -f $(COMPOSE_FILE) ps
	@echo ""
	@echo "$(GREEN)🏥 Santé des conteneurs :$(NC)"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
	@echo ""
	@echo "$(GREEN)💾 Utilisation des volumes :$(NC)"
	@docker system df
```

---

## 🚀 **Mise en place étape par étape** {#etapes}

### **Étape 1 : Préparation de l'environnement**

```bash
# Créer la structure de dossiers
mkdir -p inception/secrets
mkdir -p inception/srcs/requirements/{nginx,wordpress,mariadb}/{conf,tools}

# Naviguer dans le projet
cd inception
```

### **Étape 2 : Configuration des secrets Docker**

```bash
# Créer les fichiers de mots de passe
echo "wppassword" > secrets/db_password.txt
echo "rootpassword" > secrets/db_root_password.txt

# Créer le fichier des utilisateurs WordPress
cat > secrets/credentials.txt << EOF
jdoe:adminpass123
regularuser:userpass123
EOF
```

### **Étape 3 : Variables d'environnement**

```bash
# Créer le fichier .env
cat > srcs/.env << 'EOF'
DOMAIN_NAME=jalbiser.42.fr

# MYSQL SETUP
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=wppassword
MYSQL_ROOT_PASSWORD=rootpassword

# WORDPRESS SETUP
WP_ADMIN_USER=jdoe
WP_ADMIN_PASSWORD=adminpass123
WP_ADMIN_EMAIL=admin@jalbiser.42.fr
WP_USER=regularuser
WP_USER_PASSWORD=userpass123
WP_USER_EMAIL=user@jalbiser.42.fr

# PATHS
MYSQL_DATA_PATH=/home/jalbiser/data/mysql
WP_DATA_PATH=/home/jalbiser/data/wordpress
EOF
```

### **Étape 4 : Docker Compose**

```yaml
# Créer srcs/docker-compose.yml
version: '3.8'

services:
  nginx:
    build:
      context: ./requirements/nginx
      dockerfile: Dockerfile
    container_name: nginx
    image: nginx:custom
    ports:
      - "443:443"
    volumes:
      - wp_data:/var/www/html:ro
    depends_on:
      - wordpress
    networks:
      - inception
    restart: unless-stopped
    env_file:
      - .env

  wordpress:
    build:
      context: ./requirements/wordpress
      dockerfile: Dockerfile
    container_name: wordpress
    image: wordpress:custom
    volumes:
      - wp_data:/var/www/html
    depends_on:
      - mariadb
    networks:
      - inception
    restart: unless-stopped
    env_file:
      - .env
    secrets:
      - db_password
      - db_root_password

  mariadb:
    build:
      context: ./requirements/mariadb
      dockerfile: Dockerfile
    container_name: mariadb
    image: mariadb:custom
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - inception
    restart: unless-stopped
    env_file:
      - .env
    secrets:
      - db_password
      - db_root_password

volumes:
  wp_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/jalbiser/data/wordpress
  db_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/jalbiser/data/mysql

networks:
  inception:
    driver: bridge

secrets:
  db_password:
    file: ../secrets/db_password.txt
  db_root_password:
    file: ../secrets/db_root_password.txt
```

### **Étape 5 : Configuration NGINX**

```dockerfile
# srcs/requirements/nginx/Dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Créer certificat SSL
RUN mkdir -p /etc/ssl/certs && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/certs/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=FR/ST=Paris/L=Paris/O=42/OU=42/CN=jalbiser.42.fr"

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/start.sh /usr/local/bin/start.sh

RUN chmod +x /usr/local/bin/start.sh

EXPOSE 443

CMD ["/usr/local/bin/start.sh"]
```

### **Étape 6 : Configuration WordPress**

```dockerfile
# srcs/requirements/wordpress/Dockerfile
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

# Installer WP-CLI
RUN wget https://github.com/wp-cli/wp-cli/releases/download/v2.5.0/wp-cli-2.5.0.phar -O wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Configuration PHP-FPM
RUN mkdir -p /run/php && \
    sed -i 's/listen = \/run\/php\/php7.4-fpm.sock/listen = 9000/' /etc/php/7.4/fpm/pool.d/www.conf && \
    sed -i 's/;listen.mode = 0660/listen.mode = 0660/' /etc/php/7.4/fpm/pool.d/www.conf && \
    sed -i 's/;daemonize = yes/daemonize = no/' /etc/php/7.4/fpm/php-fpm.conf

RUN mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html

COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf
COPY tools/setup.sh /usr/local/bin/setup.sh

RUN chmod +x /usr/local/bin/setup.sh

WORKDIR /var/www/html

EXPOSE 9000

CMD ["/usr/local/bin/setup.sh"]
```

### **Étape 7 : Configuration MariaDB**

```dockerfile
# srcs/requirements/mariadb/Dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/setup.sh /usr/local/bin/setup.sh

RUN chmod +x /usr/local/bin/setup.sh

RUN mkdir -p /var/lib/mysql && \
    chown -R mysql:mysql /var/lib/mysql

EXPOSE 3306

CMD ["/usr/local/bin/setup.sh"]
```

### **Étape 8 : Makefile d'automatisation**

```makefile
# Makefile
all: up

up:
	sudo mkdir -p /home/jalbiser/data/wordpress
	sudo mkdir -p /home/jalbiser/data/mysql
	sudo chown -R jalbiser:jalbiser /home/jalbiser/data
	docker-compose -f srcs/docker-compose.yml up -d --build

down:
	docker-compose -f srcs/docker-compose.yml down

clean:
	docker-compose -f srcs/docker-compose.yml down --rmi all --volumes

fclean: clean
	sudo rm -rf /home/jalbiser/data/wordpress/*
	sudo rm -rf /home/jalbiser/data/mysql/*
	docker system prune -af

re: fclean up

.PHONY: all up down clean fclean re
```

---

## ✅ **Tests et validation** {#tests}

### **1. Lancement du projet**
```bash
make up
```

### **2. Vérification des conteneurs**
```bash
docker ps
```

### **3. Test HTTPS**
```bash
curl -k https://jalbiser.42.fr:443
```

### **4. Accès à l'interface WordPress**
- URL : `https://jalbiser.42.fr:443/wp-admin/`
- Admin : `jdoe` / `adminpass123`
- Utilisateur : `regularuser` / `userpass123`

---

## 🔧 **Dépannage** {#depannage}

### **Problèmes courants :**

1. **Erreur de certificat SSL**
   - Normal avec certificat auto-signé
   - Accepter l'avertissement du navigateur

2. **WordPress ne se connecte pas à MariaDB**
   - Vérifier les logs : `docker logs mariadb`
   - Vérifier les secrets Docker

3. **Erreur de permissions**
   - Vérifier les propriétaires des volumes
   - `sudo chown -R jalbiser:jalbiser /home/jalbiser/data`

4. **Port 443 déjà utilisé**
   - Arrêter autres services web : `sudo systemctl stop apache2 nginx`

### **Commandes utiles :**
```bash
# Voir les logs
docker logs nginx
docker logs wordpress  
docker logs mariadb

# Nettoyer complètement
make fclean

# Redémarrer
make re
```

---

## 🎉 **Projet terminé !**

Votre infrastructure Inception est maintenant fonctionnelle avec :
- ✅ NGINX + SSL/TLS sur port 443
- ✅ WordPress + PHP-FPM opérationnel
- ✅ MariaDB avec données persistantes
- ✅ Utilisateurs WordPress configurés
- ✅ Volumes et réseau Docker

Le site est accessible sur `https://jalbiser.42.fr:443` ! 🚀