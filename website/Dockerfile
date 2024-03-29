ARG DISTRO
ARG BUILD_PHP_VERSION
FROM php:${BUILD_PHP_VERSION:-8.1.12}-fpm-${DISTRO:-buster}

# ------------------------------------------------------------------------
# Install requirements
# ------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        vim \
        sudo \
        curl \
        wget \
        unzip \
        procps \
        supervisor \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libxml2-dev \
        libbz2-dev \
        libxslt-dev \
        libzip-dev

# ------------------------------------------------------------------------
# Install php extenstions See: https://hub.docker.com/_/php
# See: https://github.com/mlocati/docker-php-extension-installer
# ------------------------------------------------------------------------

RUN docker-php-ext-configure gd --with-freetype --with-jpeg

RUN docker-php-ext-install -j$(nproc) gd bcmath pcntl shmop soap \
            sockets sysvsem sysvshm zip  \
            bz2 gettext mysqli pdo_mysql xsl opcache

# Intasll redis extension
ARG REDIS_VERSION=
RUN if [ "${REDIS_VERSION}" != "" ]; then \
    pecl install redis-${REDIS_VERSION} \
    && docker-php-ext-enable redis \
;fi

# Install xdebug extension
ARG XDEBUG_VERSION=
RUN if [ "${XDEBUG_VERSION}" != "" ]; then \
    pecl install xdebug-${XDEBUG_VERSION} \
    && docker-php-ext-enable xdebug \
;fi

# Install swoole extension
ARG SWOOLE_VERSION=
RUN if [ "${SWOOLE_VERSION}" != "" ]; then \
    pecl install swoole-${SWOOLE_VERSION} && \
    docker-php-ext-enable swoole \
;fi

# Install grpc extension
ARG GRPC_VERSION=
RUN if [ "${GRPC_VERSION}" != "" ]; then \
    pecl install grpc-${GRPC_VERSION} && \
    docker-php-ext-enable grpc \
;fi

# Install protobuf extension
ARG PROTOBUF_VERSION=
RUN if [ "${PROTOBUF_VERSION}" != "" ]; then \
    pecl install protobuf-${PROTOBUF_VERSION} && \
    docker-php-ext-enable protobuf \
;fi

# Install imagick extension
ARG IMAGICK_VERSION=
RUN if [ "${IMAGICK_VERSION}" != "" ]; then \
    apt-get install -y libmagickwand-dev --no-install-recommends && \
    pecl install imagick-${IMAGICK_VERSION} && \
    docker-php-ext-enable imagick \
;fi

# Install yaf extension
ARG YAF_VERSION=
RUN if [ "${YAF_VERSION}" != "" ]; then \
    pecl install yaf-${YAF_VERSION} \
	&& docker-php-ext-enable yaf \
;fi

# Install newrelic extension
# Arm64 not supported yet
# @link https://docs.newrelic.com/docs/apm/agents/php-agent/installation/php-agent-installation-arm64/
ARG WITH_NEWRELIC=false
RUN if [ ${WITH_NEWRELIC} = true ]; then \
    apt-get install -y wget sudo gnupg2 && \
    wget -O- https://download.newrelic.com/548C16BF.gpg | sudo apt-key add - && \
    sudo sh -c 'echo "deb http://apt.newrelic.com/debian/ newrelic non-free" \
    	> /etc/apt/sources.list.d/newrelic.list' && \
    sudo apt-get update && \
    sudo apt-get install -y newrelic-php5 && \
    sudo newrelic-install install \
;fi

# ------------------------------------------------------------------------
# Install Composer
# See: https://getcomposer.org/download/
# ------------------------------------------------------------------------
ARG COMPOSER_VERSION=
RUN if [ "${COMPOSER_VERSION}" != "" ]; then \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --version=${COMPOSER_VERSION} && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer \
;fi

# ------------------------------------------------------------------------
# Install openresty
# See: https://openresty.org/cn/installation.html
# See: https://openresty.org/cn/linux-packages.html
# ------------------------------------------------------------------------
RUN addgroup --system --gid 101 nginx
RUN adduser --system --disabled-login --ingroup nginx --no-create-home --home \
    /nonexistent --gecos "nginx user" --shell /bin/false --uid 101 nginx
RUN apt-get -y install --no-install-recommends wget gnupg ca-certificates
RUN wget --no-check-certificate -O - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
RUN apt-get -y install --no-install-recommends software-properties-common
RUN codename=`grep -Po 'VERSION="[0-9]+ \(\K[^)]+' /etc/os-release` && \
    arch=$(arch | sed s/aarch64/arm64\\// | sed s/x86_64//) && \
    echo "deb http://openresty.org/package/${arch}debian $codename openresty" \
    | sudo tee /etc/apt/sources.list.d/openresty.list
RUN apt-get update && apt-get -y install openresty

# ------------------------------------------------------------------------
# Install openresty lua package: lua-resty-waf
# See: https://github.com/codiy1992/lua-resty-waf
# ------------------------------------------------------------------------
ARG RESTY_WAF_VERSION=
RUN if [ "${RESTY_WAF_VERSION}" != "" ]; then \
    opm get codiy1992/lua-resty-waf=${RESTY_WAF_VERSION} \
;fi

# ------------------------------------------------------------------------
# Install tls certificates
# ------------------------------------------------------------------------
RUN apt-get install -y apt-transport-https ca-certificates

# ------------------------------------------------------------------------
# Configure vim
# ------------------------------------------------------------------------
RUN wget -O /root/.vimrc https://gist.githubusercontent.com/codiy1992/a97395d00ca48c4c3ed92c1aa472b12c/raw/ec2.vimrc

# ------------------------------------------------------------------------
# Configure Crontab
# ------------------------------------------------------------------------
RUN apt-get install -y cron
COPY ./crontab /etc/crontab
RUN crontab /etc/crontab

# ------------------------------------------------------------------------
# [Optional] Install Ffmpeg
# ------------------------------------------------------------------------
ARG WITH_FFMPEG=false
RUN if [ ${WITH_FFMPEG} = true ]; then \
    apt-get install -y ffmpeg mkvtoolnix \
;fi

# ------------------------------------------------------------------------
# [Optional] Install Python requirements
# ------------------------------------------------------------------------
ARG WITH_PY_MODULES=false
RUN if [ ${WITH_PY_MODULES} = true ]; then \
    apt-get install -y --allow-unauthenticated python-pip && \
    pip install pyyaml schedule \
;fi

# ------------------------------------------------------------------------
# [Optional] Install gocron requirements
# ------------------------------------------------------------------------
ARG GOCRON_VERSION=
RUN if [ "${GOCRON_VERSION}" != "" ]; then \
    arch=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64/) && \
    wget -O  gocron.tar.gz \
    https://github.com/codiy1992/gocron/releases/download/v${GOCRON_VERSION}/gocron-v${GOCRON_VERSION}-linux-${arch}.tar.gz && \
    tar zxf gocron.tar.gz && \
    mv gocron-linux-${arch}/gocron* /usr/bin/ && \
    wget -O  gocron-node.tar.gz \
    https://github.com/codiy1992/gocron/releases/download/v${GOCRON_VERSION}/gocron-node-v${GOCRON_VERSION}-linux-${arch}.tar.gz && \
    tar zxf gocron-node.tar.gz && \
    mv gocron-node-linux-${arch}/gocron* /usr/bin/ \
;fi

# ------------------------------------------------------------------------
# [Optional] Install Beanstalkd
# ------------------------------------------------------------------------
ARG WITH_BEANSTALK=false
RUN if [ ${WITH_BEANSTALK} = true ]; then \
    apt-get install -y beanstalkd \
;fi

# ------------------------------------------------------------------------
# Copy Configure Files And Setup
# ------------------------------------------------------------------------

RUN rm -fr /usr/local/etc/php-fpm.d/*
COPY php /usr/local/etc/php
COPY php-fpm.conf /usr/local/etc/php-fpm.conf
COPY php-fpm.d /usr/local/etc/php-fpm.d
COPY nginx/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY nginx/sites.d/laravel.conf /usr/local/openresty/nginx/conf/sites.d/default.conf
COPY supervisor.d/init.conf /etc/supervisor/conf.d/init.conf
COPY supervisor.d/nginx.conf /etc/supervisor/conf.d/nginx.conf
COPY supervisor.d/php-fpm.conf /etc/supervisor/conf.d/php-fpm.conf

ARG BUILD_ENV
ENV ENV=${BUILD_ENV:-production}
RUN if [ "${BUILD_ENV}" = "production" ]; then \
    sed -i '/phar.readonly/d' /usr/local/etc/php/php.ini \
;fi
RUN if [ "${XDEBUG_VERSION}" = "" ]; then \
    rm -fr /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
;fi
RUN if [ "${SWOOLE_VERSION}" = "" ]; then \
    rm -fr /usr/local/etc/php/conf.d/docker-php-ext-swoole.ini \
;fi
RUN if [ "${GRPC_VERSION}" = "" ]; then \
    rm -fr /usr/local/etc/php/conf.d/docker-php-ext-grpc.ini \
;fi
RUN if [ "${PROTOBUF_VERSION}" = "" ]; then \
    rm -fr /usr/local/etc/php/conf.d/docker-php-ext-protobuf.ini \
;fi
RUN if [ "${YAF_VERSION}" = "" ]; then \
    rm -fr /usr/local/etc/php/conf.d/docker-php-ext-yaf.ini \
;fi
RUN if [ ${WITH_NEWRELIC} = false ]; then \
    rm -fr /usr/local/etc/php/conf.d/newrelic.ini \
;fi

RUN mkdir -p /data
RUN chown -R www-data.www-data /data
RUN echo 'umask 0000' >> /root/.bashrc

# ------------------------------------------------------------------------
# Start Services
# ------------------------------------------------------------------------
WORKDIR /data

STOPSIGNAL SIGQUIT

CMD ["supervisord", "--nodaemon"]
