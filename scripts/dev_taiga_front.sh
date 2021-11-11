#!/bin/bash

mkdir -p ./taiga-front/dist/plugins

cp ./config/front-config.json ./taiga-front/dist/conf.json

# Install INPS theme

cd ./taiga-front/app/themes
if [ -L inps ] ; then
   if [ -e inps ] ; then
      echo "Theme INPS already linked"
   else
      echo "Theme INPS is broken"
   fi
elif [ -e inps ] ; then
   echo "Theme INPS is not a link"
else
    ln -s ../../../taiga-inps-theme inps
fi

cd ../../../

# Install INPS plugin

cd ./taiga-front/dist/plugins
if [ -L inps ] ; then
   if [ -e inps ] ; then
      echo "Plugin INPS already linked"
   else
      echo "Plugin INPS is broken"
   fi
elif [ -e inps ] ; then
   echo "Plugin INPS is not a link"
else
    ln -s ../../../taiga-contrib-inps/front/dist inps
fi
cd ../../

cp -R ../taiga-contrib-inps/front/custom-taiga-override/. .

npm i
./node_modules/.bin/gulp deploy
