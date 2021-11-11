FROM node:12 as builder

WORKDIR /

RUN wget "https://github.com/kaleidos-ventures/taiga-front/archive/refs/tags/6.4.2.zip" -O "taiga-front.zip"
RUN unzip "taiga-front.zip"
RUN mv taiga-front-6.4.2 taiga-front

COPY ./taiga-contrib-inps/front/custom-taiga-override/. /taiga-front/

RUN mkdir /taiga-front/dist

COPY ./config/front-config.json /taiga-front/dist/conf.json

RUN mkdir -p /taiga-front/app/themes/inps
COPY ./taiga-inps-theme/. /taiga-front/app/themes/inps/

WORKDIR /taiga-front
RUN npm install
RUN npx gulp deploy


FROM nginx
EXPOSE 80
COPY ./docker/front/nginx-front.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /taiga-front/dist/ /usr/share/nginx/html/

