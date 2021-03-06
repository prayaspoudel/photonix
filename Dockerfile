FROM python:3.8.1-slim-buster

RUN apt-get update && \
    apt-get install -y \
        curl \
        dcraw \
        build-essential \
        gnupg \
        libimage-exiftool-perl \
        libjpeg-dev \
        libpq-dev \
        libtiff5-dev \
        netcat \
        nginx-light \
        supervisor \
        && \
        apt-get clean && \
            rm -rf /var/lib/apt/lists/* \
                   /tmp/* \
                   /var/tmp/*

# Install Node & Yarn
RUN curl -sL https://deb.nodesource.com/setup_13.x | bash - && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -y nodejs yarn && \
         apt-get clean && \
            rm -rf /var/lib/apt/lists/* \
                   /tmp/* \
                   /var/tmp/*

# Install NPM dependencies
COPY ui/package.json /srv/ui/package.json
COPY ui/yarn.lock /srv/ui/yarn.lock
COPY ui/config /srv/ui/config
COPY ui/scripts /srv/ui/scripts
WORKDIR /srv/ui
RUN yarn install

# Install Python dependencies
WORKDIR /srv
COPY requirements.txt /srv/requirements.txt
RUN sed -i "s|tensorflow==2.1.0|https://github.com/damianmoore/tensorflow-builder/releases/download/v2.1.0/tensorflow-2.1.0-cp38-cp38-linux_x86_64.whl|g" /srv/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy over the code
COPY photonix /srv/photonix
COPY ui/public /srv/ui/public
COPY ui/src /srv/ui/src

# Copy system config and init scripts
COPY system /srv/system
COPY system/supervisord.conf /etc/supervisord.conf

# Build frontend app
RUN cd ui && yarn build

ENV PYTHONPATH /srv

CMD ./system/run.sh

EXPOSE 80
