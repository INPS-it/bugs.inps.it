#!/bin/bash

git clone --branch 6.4.2 https://github.com/kaleidos-ventures/taiga-front.git

cp ./config/front-config.json ./taiga-front/conf/conf.json

# Install INPS theme
cp -R ./taiga-inps-theme/. ./taiga-front/app/themes/inps/
cp -R ./taiga-contrib-inps/front/custom-taiga-override/. ./taiga-front/

# Run local dev docker compose
docker compose -f docker-compose.yml -f docker-compose.dev.yml up
