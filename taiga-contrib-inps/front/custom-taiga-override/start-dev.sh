#!/bin/bash

cd /taiga-contrib-inps-front
./watch.sh  ./app/ /taiga-front &

cd /taiga-inps-theme
/taiga-contrib-inps-front/watch.sh  ./ /taiga-front/app/themes/inps &

cd /taiga-front
/taiga-front/node_modules/.bin/gulp --theme inps