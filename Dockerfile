FROM alpine

MAINTAINER Matteo Capitanio <matteo.capitanio@gmail.com>

ENV CADDY_VER 0.10.14

# Install needed packages
RUN apk update; \
    apk add --no-cache -u ca-certificates python py-pip git wget nodejs-npm bash sudo curl; \
    echo "progress = dot:giga" | tee /etc/wgetrc
RUN pip install supervisor

WORKDIR /

# Add and Setup Caddy webserver
RUN wget "https://github.com/mholt/caddy/releases/download/v${CADDY_VER}/caddy_v${CADDY_VER}_linux_amd64.tar.gz" -O /caddy.tgz \
    && mkdir caddy \
    && tar xzf caddy.tgz -C /caddy \
    && rm -f /caddy.tgz

RUN npm i npm@latest -g; \
    npm install -g bower
RUN adduser parrot -D -h /kafka-connect-ui; \
    chown parrot:parrot /kafka-connect-ui
    
USER parrot

WORKDIR /kafka-connect-ui

ADD src src
ADD *.* ./
#ADD docker.parrot/env.js ./
RUN npm install
RUN npm run-script postinstall
RUN npm run-script build

WORKDIR /

USER root

ADD docker.parrot/etc/ /etc/
ADD docker.parrot/Caddyfile.template /caddy/
ADD docker.parrot/*.sh /
RUN chmod o=rx /*.sh; \
    chmod o=rxw /caddy
RUN chown parrot:parrot -R /kafka-connect-ui; \
    chown parrot:parrot -R /caddy/Caddyfile.template

USER parrot

EXPOSE 8000

ENTRYPOINT ["supervisord", "-c", "/etc/supervisord.conf", "-n"]
