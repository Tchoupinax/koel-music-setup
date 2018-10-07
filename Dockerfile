FROM debian:stretch

RUN apt-get update

RUN apt-get update \
    && apt-get install -y php php-xml php-mbstring php-curl \ 
    php-zip php-pgsql postgresql apache2 \
    && apt-get install -y curl git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LO "https://nodejs.org/dist/v10.0.0/node-v10.0.0-linux-x64.tar.gz" \
    && tar -xzf node-v10.0.0-linux-x64.tar.gz -C /usr/local --strip-components=1 \
    && rm node-v10.0.0-linux-x64.tar.gz

RUN cd /opt && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \ 
    && php -r "if (hash_file('SHA384', 'composer-setup.php') === '93b54496392c062774670ac18b134c3b3a95e5a5e5c8f1a9f115f203b75bf9a129d5daa8ba6a13e2cc8a1da0806388a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');" \
    && mv composer.phar /bin/composer

ADD ./koel /opt/koel

RUN cd /opt/koel \
    && /bin/composer install

RUN apt-get update && apt-get install -y python make build-essential g++ gcc

RUN cd /opt/koel \
    && npm i -g yarn \
    && npm update && npm install --unsafe-perm=true --allow-root

RUN service postgresql start \
    && apt-get install sudo \
    && sudo -u postgres createuser --no-superuser koel \
    && sudo -u postgres psql -c "ALTER USER koel PASSWORD 'koel';" \
    && sudo -u postgres psql -c "CREATE database koel WITH OWNER koel ENCODING 'utf8';" \
    && sudo -u postgres psql -c "grant all privileges on database koel to koel;"

RUN cd /opt/koel \ 
    && php artisan koel:init


# # Installation de Node.js à partir du site officiel
# RUN curl -LO "https://nodejs.org/dist/v10.0.0/node-v10.0.0-linux-x64.tar.gz" \
#     && tar -xzf node-v10.0.0-linux-x64.tar.gz -C /usr/local --strip-components=1 \
#     && rm node-v10.0.0-linux-x64.tar.gz

# # Ajout du fichier de dépendances package.json
# ADD package.json /app/

# # Changement du repertoire courant
# WORKDIR /app

# # Load postgres
# RUN /etc/init.d/postgresql start \
#     && sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'secret';"

# # Installation des dépendances
# RUN npm install

# # Ajout des sources
# ADD . /app/

# # On expose le port 80
# EXPOSE 3456

# # On partage un dossier de log
# VOLUME /app/log

# # On lance le serveur quand on démarre le conteneur
# CMD /etc/init.d/postgresql start \
#     && psql postgres://postgres:secret@localhost/postgres --file db/save-db.sql \
#     && ENV=docker node src/index.js