#
#--------------------------------------------------------------------------
# Image Setup
#--------------------------------------------------------------------------
#
# To edit the 'php-fpm' base Image, visit its repository on Github
#    https://github.com/Laradock/php-fpm
#
# To change its version, see the available Tags on the Docker Hub:
#    https://hub.docker.com/r/laradock/php-fpm/tags/
#
# Note: Base Image name format {image-tag}-{php-version}
#

ARG LARADOCK_PHP_VERSION=7.3
FROM php:7.3.27-fpm

LABEL maintainer="dq042000 <dq042000@gmail.com>"

# Set Environment Variables
ENV DEBIAN_FRONTEND noninteractive

# If you're in China, or you need to change sources, will be set CHANGE_SOURCE to true in .env.

ARG CHANGE_SOURCE=false
RUN if [ ${CHANGE_SOURCE} = true ]; then \
    # Change application source from deb.debian.org to aliyun source
    sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/mirrors.tuna.tsinghua.edu.cn/' /etc/apt/sources.list && \
    sed -i 's/security-cdn.debian.org/mirrors.tuna.tsinghua.edu.cn/' /etc/apt/sources.list \
;fi

# always run apt update when start and after add new source list, then clean up at end.
RUN set -xe; \
    apt-get update -yqq && \
    pecl channel-update pecl.php.net && \
    apt-get install -yqq \
      apt-utils \
      gnupg2 \
      git \
      #
      #--------------------------------------------------------------------------
      # Mandatory Software's Installation
      #--------------------------------------------------------------------------
      #
      # Mandatory Software's such as ("mcrypt", "pdo_mysql", "libssl-dev", ....)
      # are installed on the base image 'laradock/php-fpm' image. If you want
      # to add more Software's or remove existing one, you need to edit the
      # base image (https://github.com/Laradock/php-fpm).
      #
      # next lines are here becase there is no auto build on dockerhub see https://github.com/laradock/laradock/pull/1903#issuecomment-463142846
      libzip-dev zip unzip && \
      if [ ${LARADOCK_PHP_VERSION} = "7.3" ] || [ ${LARADOCK_PHP_VERSION} = "7.4" ] || [ $(php -r "echo PHP_MAJOR_VERSION;") = "8" ]; then \
        docker-php-ext-configure zip; \
      else \
        docker-php-ext-configure zip --with-libzip; \
      fi && \
      # Install the zip extension
      docker-php-ext-install zip && \
      php -m | grep -q 'zip'

#
#--------------------------------------------------------------------------
# Optional Software's Installation
#--------------------------------------------------------------------------
#
# Optional Software's will only be installed if you set them to `true`
# in the `docker-compose.yml` before the build.
# Example:
#   - INSTALL_SOAP=true
#


###########################################################################
# GD
###########################################################################

RUN apt-get -yqq install \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev && \
    docker-php-ext-configure gd --with-freetype-dir --with-jpeg-dir && \
    # Install the gd extension
    docker-php-ext-install gd

###########################################################################
# BZ2:
###########################################################################

ARG INSTALL_BZ2=true
RUN if [ ${INSTALL_BZ2} = true ]; then \
  apt-get -yqq install libbz2-dev; \
  docker-php-ext-install bz2 \
;fi

###########################################################################
# Enchant:
###########################################################################

ARG INSTALL_ENCHANT=false
RUN if [ ${INSTALL_ENCHANT} = true ]; then \
  apt-get install -yqq libenchant-dev; \
  docker-php-ext-install enchant; \
  php -m | grep -oiE '^enchant$'; \
fi

###########################################################################
# GMP (GNU Multiple Precision):
###########################################################################

ARG INSTALL_GMP=true
RUN if [ ${INSTALL_GMP} = true ]; then \
    # Install the GMP extension
	  apt-get install -yqq libgmp-dev && \
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
      ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h \
    ;fi && \
    docker-php-ext-install gmp \
;fi

###########################################################################
# GnuPG:
###########################################################################

ARG INSTALL_GNUPG=true
RUN if [ ${INSTALL_GNUPG} = true ]; then \
      apt-get -yq install libgpgme-dev; \
      if [ $(php -r "echo PHP_MAJOR_VERSION;") = "8" ]; then \
        pecl install gnupg-1.5.0RC2; \
      else \
        pecl install gnupg; \
      fi; \
      docker-php-ext-enable gnupg; \
      php -m | grep -q 'gnupg'; \
    fi

###########################################################################
# SSH2:
###########################################################################

ARG INSTALL_SSH2=true
RUN if [ ${INSTALL_SSH2} = true ]; then \
    # Install the ssh2 extension
    apt-get -y install libssh2-1-dev && \
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
        pecl install -a ssh2-0.13; \
    else \
        pecl install -a ssh2-1.3.1; \
    fi && \
    docker-php-ext-enable ssh2 \
;fi

###########################################################################
# libfaketime:
###########################################################################

USER root

ARG INSTALL_FAKETIME=false
RUN if [ ${INSTALL_FAKETIME} = true ]; then \
    apt-get install -yqq libfaketime \
;fi

###########################################################################
# SOAP:
###########################################################################

ARG INSTALL_SOAP=true
RUN if [ ${INSTALL_SOAP} = true ]; then \
    # Install the soap extension
    rm /etc/apt/preferences.d/no-debian-php && \
    apt-get -y install libxml2-dev php-soap && \
    docker-php-ext-install soap \
;fi

###########################################################################
# XSL:
###########################################################################

ARG INSTALL_XSL=true
RUN if [ ${INSTALL_XSL} = true ]; then \
    # Install the xsl extension
    apt-get -y install libxslt-dev && \
    docker-php-ext-install xsl \
;fi

###########################################################################
# pgsql
###########################################################################

ARG INSTALL_PGSQL=true
RUN if [ ${INSTALL_PGSQL} = true ]; then \
    # Install the pgsql extension
    apt-get -y install libpq-dev && \
    docker-php-ext-install pgsql \
;fi

###########################################################################
# pgsql client
###########################################################################

ARG INSTALL_PG_CLIENT=true
ARG INSTALL_POSTGIS=true
RUN if [ ${INSTALL_PG_CLIENT} = true ]; then \
    apt-get install -yqq gnupg \
    && . /etc/os-release \
    && echo "deb http://apt.postgresql.org/pub/repos/apt $VERSION_CODENAME-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && curl -sL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && apt-get update -yqq \
    && apt-get install -yqq postgresql-client-12 postgis; \
    if [ ${INSTALL_POSTGIS} = true ]; then \
      apt-get install -yqq postgis; \
    fi \
    && apt-get purge -yqq gnupg \
;fi

###########################################################################
# xDebug:
###########################################################################

ARG INSTALL_XDEBUG=true
RUN if [ ${INSTALL_XDEBUG} = true ]; then \
  # Install the xdebug extension
  # https://xdebug.org/docs/compat
  if [ $(php -r "echo PHP_MAJOR_VERSION;") = "8" ] || { [ $(php -r "echo PHP_MAJOR_VERSION;") = "7" ] && { [ $(php -r "echo PHP_MINOR_VERSION;") = "4" ] || [ $(php -r "echo PHP_MINOR_VERSION;") = "3" ] ;} ;}; then \
    pecl install xdebug-3.1.1; \
  else \
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
      pecl install xdebug-2.5.5; \
    else \
      if [ $(php -r "echo PHP_MINOR_VERSION;") = "0" ]; then \
        pecl install xdebug-2.9.0; \
      else \
        pecl install xdebug-2.9.8; \
      fi \
    fi \
  fi && \
  docker-php-ext-enable xdebug \
;fi

# Copy xdebug configuration for remote debugging
COPY ./xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

RUN if [ $(php -r "echo PHP_MAJOR_VERSION;") = "8" ]; then \
  sed -i "s/xdebug.remote_host=/xdebug.client_host=/" /usr/local/etc/php/conf.d/xdebug.ini && \
  sed -i "s/xdebug.remote_connect_back=0/xdebug.discover_client_host=false/" /usr/local/etc/php/conf.d/xdebug.ini && \
  sed -i "s/xdebug.remote_port=9000/xdebug.client_port=9003/" /usr/local/etc/php/conf.d/xdebug.ini && \
  sed -i "s/xdebug.profiler_enable=0/; xdebug.profiler_enable=0/" /usr/local/etc/php/conf.d/xdebug.ini && \
  sed -i "s/xdebug.profiler_output_dir=/xdebug.output_dir=/" /usr/local/etc/php/conf.d/xdebug.ini && \
  sed -i "s/xdebug.remote_mode=req/; xdebug.remote_mode=req/" /usr/local/etc/php/conf.d/xdebug.ini && \
  sed -i "s/xdebug.remote_autostart=0/xdebug.start_with_request=yes/" /usr/local/etc/php/conf.d/xdebug.ini && \
  sed -i "s/xdebug.remote_enable=0/xdebug.mode=debug/" /usr/local/etc/php/conf.d/xdebug.ini \
;else \
  sed -i "s/xdebug.remote_autostart=0/xdebug.remote_autostart=1/" /usr/local/etc/php/conf.d/xdebug.ini && \
  sed -i "s/xdebug.remote_enable=0/xdebug.remote_enable=1/" /usr/local/etc/php/conf.d/xdebug.ini \
;fi
RUN sed -i "s/xdebug.cli_color=0/xdebug.cli_color=1/" /usr/local/etc/php/conf.d/xdebug.ini

###########################################################################
# pcov:
###########################################################################

USER root

ARG INSTALL_PCOV=true
RUN if [ ${INSTALL_PCOV} = true ]; then \
  if [ $(php -r "echo PHP_MAJOR_VERSION;") = "7" ]; then \
    if [ $(php -r "echo PHP_MINOR_VERSION;") != "0" ]; then \
      pecl install pcov && \
      docker-php-ext-enable pcov \
    ;fi \
  ;fi \
;fi

###########################################################################
# Phpdbg:
###########################################################################

ARG INSTALL_PHPDBG=false
RUN if [ ${INSTALL_PHPDBG} = true ]; then \
    # Load the xdebug extension only with phpunit commands
    apt-get install -yqq --force-yes php${LARADOCK_PHP_VERSION}-phpdbg \
;fi

###########################################################################
# Blackfire:
###########################################################################

ARG INSTALL_BLACKFIRE=false
RUN if [ ${INSTALL_XDEBUG} = false -a ${INSTALL_BLACKFIRE} = true ]; then \
    version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/$version \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp \
    && mv /tmp/blackfire-*.so $(php -r "echo ini_get('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > $PHP_INI_DIR/conf.d/blackfire.ini \
;fi

###########################################################################
# PHP REDIS EXTENSION
###########################################################################

ARG INSTALL_PHPREDIS=true
RUN if [ ${INSTALL_PHPREDIS} = true ]; then \
    # Install Php Redis Extension
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
      pecl install -o -f redis-4.3.0; \
    else \
      pecl install -o -f redis; \
    fi \
    && rm -rf /tmp/pear \
    && docker-php-ext-enable redis \
;fi

###########################################################################
# Swoole EXTENSION
###########################################################################

ARG INSTALL_SWOOLE=false
RUN set -eux; \
    if [ ${INSTALL_SWOOLE} = true ]; then \
      # Install Php Swoole Extension
      if   [ $(php -r "echo PHP_VERSION_ID - PHP_RELEASE_VERSION;") = "50600" ]; then \
        pecl install swoole-2.0.10; \
      elif [ $(php -r "echo PHP_VERSION_ID - PHP_RELEASE_VERSION;") = "70000" ]; then \
        pecl install swoole-4.3.5; \
      elif [ $(php -r "echo PHP_VERSION_ID - PHP_RELEASE_VERSION;") = "70100" ]; then \
        pecl install swoole-4.5.11; \
      else \
        pecl install swoole; \
      fi; \
      docker-php-ext-enable swoole; \
      php -m | grep -q 'swoole'; \
    fi

###########################################################################
# Taint EXTENSION
###########################################################################

ARG INSTALL_TAINT=false
RUN if [ ${INSTALL_TAINT} = true ]; then \
    # Install Php TAINT Extension
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "7" ]; then \
      pecl install taint && \
      docker-php-ext-enable taint && \
      php -m | grep -q 'taint'; \
    fi \
;fi

###########################################################################
# MongoDB:
###########################################################################

ARG INSTALL_MONGO=true
RUN if [ ${INSTALL_MONGO} = true ]; then \
    # Install the mongodb extension
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
      pecl install mongo; \
      docker-php-ext-enable mongo; \
      php -m | grep -oiE '^mongo$'; \
    else \
      if [ $(php -r "echo PHP_VERSION_ID - PHP_RELEASE_VERSION;") = "70000" ]; then \
        pecl install mongodb-1.9.2; \
      else \
        pecl install mongodb; \
      fi; \
      docker-php-ext-enable mongodb; \
      php -m | grep -oiE '^mongodb$'; \
    fi; \
fi

###########################################################################
# Xhprof:
###########################################################################

ARG INSTALL_XHPROF=false
RUN set -eux; \
    if [ ${INSTALL_XHPROF} = true ]; then \
      # Install the php xhprof extension
      if   [ $(php -r "echo PHP_MAJOR_VERSION;") != 5 ]; then \
        pecl install xhprof; \
      else \
        curl -L -o /tmp/xhprof.tar.gz "https://codeload.github.com/phacility/xhprof/tar.gz/master"; \
        mkdir -p /tmp/xhprof; \
        tar -C /tmp/xhprof -zxvf /tmp/xhprof.tar.gz --strip 1; \
        ( \
            cd /tmp/xhprof/extension; \
            phpize; \
            ./configure; \
            make; \
            make install; \
        ); \
        rm -r /tmp/xhprof; \
        rm /tmp/xhprof.tar.gz; \
      fi; \
      docker-php-ext-enable xhprof; \
      php -m | grep -q 'xhprof'; \
    fi

# if [ ${INSTALL_XHPROF_USE_TIDYWAYS} = true ]; then \
#   https://github.com/tideways/php-xhprof-extension
# fi

# COPY ./xhprof.ini /usr/local/etc/php/conf.d

# RUN if [ ${INSTALL_XHPROF} = false ]; then \
#     rm /usr/local/etc/php/conf.d/xhprof.ini \
# ;fi

###########################################################################
# AMQP:
###########################################################################

ARG INSTALL_AMQP=false
RUN set -eux; \
    if [ ${INSTALL_AMQP} = true ]; then \
      # # Install the amqp extension
      apt-get -yqq install librabbitmq-dev; \
      if [ $(php -r "echo PHP_MAJOR_VERSION;") = "8" ]; then \
        pecl install amqp-1.11.0beta; \
      else \
        pecl install amqp; \
      fi; \
      docker-php-ext-enable amqp; \
      php -m | grep -oiE '^amqp$'; \
    fi

###########################################################################
# CASSANDRA:
###########################################################################

ARG INSTALL_CASSANDRA=false
RUN if [ ${INSTALL_CASSANDRA} = true ]; then \
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "8" ]; then \
      echo "PHP Driver for Cassandra is not supported for PHP 8.0."; \
    else \
      apt-get install libgmp-dev -yqq && \
      curl https://downloads.datastax.com/cpp-driver/ubuntu/18.04/dependencies/libuv/v1.35.0/libuv1-dev_1.35.0-1_amd64.deb -o libuv1-dev.deb && \
      curl https://downloads.datastax.com/cpp-driver/ubuntu/18.04/dependencies/libuv/v1.35.0/libuv1_1.35.0-1_amd64.deb -o libuv1.deb && \
      curl https://downloads.datastax.com/cpp-driver/ubuntu/18.04/cassandra/v2.16.0/cassandra-cpp-driver-dev_2.16.0-1_amd64.deb -o cassandra-cpp-driver-dev.deb && \
      curl https://downloads.datastax.com/cpp-driver/ubuntu/18.04/cassandra/v2.16.0/cassandra-cpp-driver_2.16.0-1_amd64.deb -o cassandra-cpp-driver.deb && \
      dpkg -i libuv1.deb && \
      dpkg -i libuv1-dev.deb && \
      dpkg -i cassandra-cpp-driver.deb && \
      dpkg -i cassandra-cpp-driver-dev.deb && \
      rm libuv1.deb libuv1-dev.deb cassandra-cpp-driver-dev.deb cassandra-cpp-driver.deb && \
      cd /usr/src && \
      git clone https://github.com/datastax/php-driver.git && \
      cd /usr/src/php-driver/ext && \
      phpize && \
      mkdir /usr/src/php-driver/build && \
      cd /usr/src/php-driver/build && \
      ../ext/configure > /dev/null && \
      make clean > /dev/null && \
      make > /dev/null 2>&1 && \
      make install && \
      echo "extension=cassandra.so" >> /etc/php/${LARADOCK_PHP_VERSION}/mods-available/cassandra.ini && \
      ln -s /etc/php/${LARADOCK_PHP_VERSION}/mods-available/cassandra.ini /etc/php/${LARADOCK_PHP_VERSION}/cli/conf.d/30-cassandra.ini; \
    fi \
;fi

###########################################################################
# GEARMAN:
###########################################################################

ARG INSTALL_GEARMAN=false
RUN if [ ${INSTALL_GEARMAN} = true ]; then \
    apt-get -y install libgearman-dev && \
    cd /tmp && \
    curl -L https://github.com/wcgallego/pecl-gearman/archive/gearman-2.0.5.zip -O && \
    unzip gearman-2.0.5.zip && \
    mv pecl-gearman-gearman-2.0.5 pecl-gearman && \
    cd /tmp/pecl-gearman && \
    phpize && \
    ./configure && \
    make -j$(nproc) && \
    make install && \
    cd / && \
    rm /tmp/gearman-2.0.5.zip && \
    rm -r /tmp/pecl-gearman && \
    docker-php-ext-enable gearman \
;fi

###########################################################################
# pcntl
###########################################################################

ARG INSTALL_PCNTL=false
RUN if [ ${INSTALL_PCNTL} = true ]; then \
    # Installs pcntl, helpful for running Horizon
    docker-php-ext-install pcntl \
;fi

###########################################################################
# bcmath:
###########################################################################

ARG INSTALL_BCMATH=true
RUN if [ ${INSTALL_BCMATH} = true ]; then \
    # Install the bcmath extension
    docker-php-ext-install bcmath \
;fi

###########################################################################
# PHP Memcached:
###########################################################################

ARG INSTALL_MEMCACHED=true
RUN if [ ${INSTALL_MEMCACHED} = true ]; then \
    # Install the php memcached extension
    apt-get install -y libmemcached-dev && \
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
      echo '' | pecl -q install memcached-2.2.0; \
    else \
      echo '' | pecl -q install memcached; \
      echo '' | pecl -q install igbinary; \
    fi \
    && docker-php-ext-enable memcached \
    && docker-php-ext-enable igbinary \
;fi

###########################################################################
# Exif:
###########################################################################

ARG INSTALL_EXIF=true
RUN if [ ${INSTALL_EXIF} = true ]; then \
    # Enable Exif PHP extentions requirements
    docker-php-ext-install exif \
;fi

###########################################################################
# PHP Aerospike:
###########################################################################

USER root

ARG INSTALL_AEROSPIKE=false
RUN set -xe; \
    if [ ${INSTALL_AEROSPIKE} = true ]; then \
    # Fix dependencies for PHPUnit within aerospike extension
    apt-get -y install sudo wget && \
    # Install the php aerospike extension
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
      curl -L -o /tmp/aerospike-client-php.tar.gz https://github.com/aerospike/aerospike-client-php5/archive/master.tar.gz; \
    else \
      curl -L -o /tmp/aerospike-client-php.tar.gz https://github.com/aerospike/aerospike-client-php/archive/master.tar.gz; \
    fi \
    && mkdir -p /tmp/aerospike-client-php \
    && tar -C /tmp/aerospike-client-php -zxvf /tmp/aerospike-client-php.tar.gz --strip 1 \
    && \
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
      ( \
          cd /tmp/aerospike-client-php/src/aerospike \
          && phpize \
          && ./build.sh \
          && make install \
      ) \
    else \
      ( \
          cd /tmp/aerospike-client-php/src \
          && phpize \
          && ./build.sh \
          && make install \
      ) \
    fi \
    && rm /tmp/aerospike-client-php.tar.gz \
    && docker-php-ext-enable aerospike \
;fi

###########################################################################
# PHP OCI8:
###########################################################################

ARG INSTALL_OCI8=false
ARG ORACLE_INSTANT_CLIENT_MIRROR=https://github.com/diogomascarenha/oracle-instantclient/raw/master/

ENV LD_LIBRARY_PATH="/opt/oracle/instantclient_12_1"
ENV OCI_HOME="/opt/oracle/instantclient_12_1"
ENV OCI_LIB_DIR="/opt/oracle/instantclient_12_1"
ENV OCI_INCLUDE_DIR="/opt/oracle/instantclient_12_1/sdk/include"
ENV OCI_VERSION=12

RUN if [ ${INSTALL_OCI8} = true ]; then \
    # Install wget
    apt-get install --no-install-recommends -yqq wget \
    # Install Oracle Instantclient
    && mkdir /opt/oracle \
        && cd /opt/oracle \
        && wget ${ORACLE_INSTANT_CLIENT_MIRROR}instantclient-basic-linux.x64-12.1.0.2.0.zip \
        && wget ${ORACLE_INSTANT_CLIENT_MIRROR}instantclient-sdk-linux.x64-12.1.0.2.0.zip \
        && unzip /opt/oracle/instantclient-basic-linux.x64-12.1.0.2.0.zip -d /opt/oracle \
        && unzip /opt/oracle/instantclient-sdk-linux.x64-12.1.0.2.0.zip -d /opt/oracle \
        && ln -s /opt/oracle/instantclient_12_1/libclntsh.so.12.1 /opt/oracle/instantclient_12_1/libclntsh.so \
        && ln -s /opt/oracle/instantclient_12_1/libclntshcore.so.12.1 /opt/oracle/instantclient_12_1/libclntshcore.so \
        && ln -s /opt/oracle/instantclient_12_1/libocci.so.12.1 /opt/oracle/instantclient_12_1/libocci.so \
        && rm -rf /opt/oracle/*.zip \
    # Install PHP extensions deps
    && apt-get install --no-install-recommends -yqq \
      libaio-dev \
      freetds-dev && \
    # Install PHP extensions
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
      echo 'instantclient,/opt/oracle/instantclient_12_1/' | pecl install oci8-2.0.12; \
    elif [ $(php -r "echo PHP_MAJOR_VERSION;") = "7" ]; then \
      echo 'instantclient,/opt/oracle/instantclient_12_1/' | pecl install oci8-2.2.0; \
    else \
      echo 'instantclient,/opt/oracle/instantclient_12_1/' | pecl install oci8; \
    fi \
        && docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/opt/oracle/instantclient_12_1,12.1 \
        && docker-php-ext-configure pdo_dblib --with-libdir=/lib/x86_64-linux-gnu \
        && docker-php-ext-install \
                pdo_oci \
        && docker-php-ext-enable \
                oci8 \
  ;fi

###########################################################################
# IonCube Loader:
###########################################################################

ARG INSTALL_IONCUBE=false

RUN if [ ${INSTALL_IONCUBE} = true ]; then \
    if [ $(php -r "echo PHP_MAJOR_VERSION;") != "8" ]; then \
      # Install the php ioncube loader
      curl -L -o /tmp/ioncube_loaders_lin_x86-64.tar.gz https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
      && tar zxpf /tmp/ioncube_loaders_lin_x86-64.tar.gz -C /tmp \
      && mv /tmp/ioncube/ioncube_loader_lin_${LARADOCK_PHP_VERSION}.so $(php -r "echo ini_get('extension_dir');")/ioncube_loader.so \
      && printf "zend_extension=ioncube_loader.so\n" > $PHP_INI_DIR/conf.d/0ioncube.ini \
      && rm -rf /tmp/ioncube* \
      && php -m | grep -oiE '^ionCube Loader$' \
    ;fi \
;fi

###########################################################################
# Opcache:
###########################################################################

ARG INSTALL_OPCACHE=true

RUN if [ ${INSTALL_OPCACHE} = true ]; then \
    docker-php-ext-install opcache \
;fi

# Copy opcache configration
COPY ./opcache.ini /usr/local/etc/php/conf.d/opcache.ini

###########################################################################
# Mysqli Modifications:
###########################################################################

ARG INSTALL_MYSQLI=true

RUN if [ ${INSTALL_MYSQLI} = true ]; then \
    docker-php-ext-install mysqli \
;fi


###########################################################################
# Human Language and Character Encoding Support:
###########################################################################

ARG INSTALL_INTL=true

RUN if [ ${INSTALL_INTL} = true ]; then \
    # Install intl and requirements
    apt-get install -yqq zlib1g-dev libicu-dev g++ && \
    docker-php-ext-configure intl && \
    docker-php-ext-install intl \
;fi

###########################################################################
# GHOSTSCRIPT:
###########################################################################

ARG INSTALL_GHOSTSCRIPT=true

RUN if [ ${INSTALL_GHOSTSCRIPT} = true ]; then \
    # Install the ghostscript extension
    # for PDF editing
    apt-get install -yqq \
    poppler-utils \
    ghostscript \
;fi

###########################################################################
# LDAP:
###########################################################################

ARG INSTALL_LDAP=true

RUN if [ ${INSTALL_LDAP} = true ]; then \
    apt-get install -yqq libldap2-dev && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
    docker-php-ext-install ldap \
;fi

###########################################################################
# SQL SERVER:
###########################################################################

ARG INSTALL_MSSQL=false

RUN set -eux; \
  if [ ${INSTALL_MSSQL} = true ]; then \
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
      apt-get -yqq install freetds-dev libsybdb5 \
      && ln -s /usr/lib/x86_64-linux-gnu/libsybdb.so /usr/lib/libsybdb.so \
      && docker-php-ext-install mssql pdo_dblib \
      && php -m | grep -oiE '^mssql$' \
      && php -m | grep -oiE '^pdo_dblib$' \
    ;else \
      ###########################################################################
      # Ref from https://github.com/Microsoft/msphpsql/wiki/Dockerfile-for-adding-pdo_sqlsrv-and-sqlsrv-to-official-php-image
      ###########################################################################
      # Add Microsoft repo for Microsoft ODBC Driver 13 for Linux
      apt-get install -yqq apt-transport-https gnupg lsb-release \
      && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
      && curl https://packages.microsoft.com/config/debian/$(lsb_release -rs)/prod.list > /etc/apt/sources.list.d/mssql-release.list \
      && apt-get update -yqq \
      && ACCEPT_EULA=Y apt-get install -yqq unixodbc unixodbc-dev libgss3 odbcinst msodbcsql17 locales \
      && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
      && ln -sfn /etc/locale.alias /usr/share/locale/locale.alias \
      && locale-gen \
      && if [ $(php -r "echo PHP_VERSION_ID - PHP_RELEASE_VERSION;") = "70000" ]; then \
        pecl install pdo_sqlsrv-5.3.0 sqlsrv-5.3.0 \
      ;elif [ $(php -r "echo PHP_VERSION_ID - PHP_RELEASE_VERSION;") = "70100" ]; then \
        pecl install pdo_sqlsrv-5.6.1 sqlsrv-5.6.1 \
      ;elif [ $(php -r "echo PHP_VERSION_ID - PHP_RELEASE_VERSION;") = "70200" ]; then \
        pecl install pdo_sqlsrv-5.8.1 sqlsrv-5.8.1 \
      ;else \
        pecl install pdo_sqlsrv sqlsrv \
      ;fi \
      && docker-php-ext-enable pdo_sqlsrv sqlsrv \
      && php -m | grep -oiE '^pdo_sqlsrv$' \
      && php -m | grep -oiE '^sqlsrv$' \
    ;fi \
  ;fi

###########################################################################
# Image optimizers:
###########################################################################

USER root

ARG INSTALL_IMAGE_OPTIMIZERS=true

RUN if [ ${INSTALL_IMAGE_OPTIMIZERS} = true ]; then \
    apt-get install -yqq jpegoptim optipng pngquant gifsicle \
;fi

###########################################################################
# ImageMagick:
###########################################################################

USER root

ARG INSTALL_IMAGEMAGICK=true
ARG IMAGEMAGICK_VERSION=latest
ENV IMAGEMAGICK_VERSION ${IMAGEMAGICK_VERSION}

RUN if [ ${INSTALL_IMAGEMAGICK} = true ]; then \
    apt-get install -yqq libmagickwand-dev imagemagick && \
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "8" ]; then \
      cd /tmp && \
      if [ ${IMAGEMAGICK_VERSION} = "latest" ]; then \
        git clone https://github.com/Imagick/imagick; \
      else \
        git clone --branch ${IMAGEMAGICK_VERSION} https://github.com/Imagick/imagick; \
      fi && \
      cd imagick && \
      phpize && \
      ./configure && \
      make && \
      make install && \
      rm -r /tmp/imagick; \
    else \
      pecl install imagick; \
    fi && \
    docker-php-ext-enable imagick; \
    php -m | grep -q 'imagick' \
;fi

###########################################################################
# SMB:
###########################################################################

ARG INSTALL_SMB=false

RUN if [ ${INSTALL_SMB} = true ]; then \
    apt-get install -yqq smbclient libsmbclient-dev coreutils && \
    pecl install smbclient && \
    docker-php-ext-enable smbclient \
;fi

###########################################################################
# IMAP:
###########################################################################

ARG INSTALL_IMAP=true

RUN if [ ${INSTALL_IMAP} = true ]; then \
    apt-get install -yqq libc-client-dev libkrb5-dev && \
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
    docker-php-ext-install imap \
;fi

###########################################################################
# Calendar:
###########################################################################

USER root

ARG INSTALL_CALENDAR=true

RUN if [ ${INSTALL_CALENDAR} = true ]; then \
    docker-php-ext-configure calendar && \
    docker-php-ext-install calendar \
;fi

###########################################################################
# Phalcon:
###########################################################################

ARG INSTALL_PHALCON=false
ARG LARADOCK_PHALCON_VERSION
ENV LARADOCK_PHALCON_VERSION ${LARADOCK_PHALCON_VERSION}

# Copy phalcon configration
COPY ./phalcon.ini /usr/local/etc/php/conf.d/phalcon.ini.disable

RUN if [ $INSTALL_PHALCON = true ]; then \
    apt-get install -yqq unzip libpcre3-dev gcc make re2c git automake autoconf\
    && git clone https://github.com/jbboehr/php-psr.git \
    && cd php-psr \
    && phpize \
    && ./configure \
    && make \
    && make test \
    && make install \
    && curl -L -o /tmp/cphalcon.zip https://github.com/phalcon/cphalcon/archive/v${LARADOCK_PHALCON_VERSION}.zip \
    && unzip -d /tmp/ /tmp/cphalcon.zip \
    && cd /tmp/cphalcon-${LARADOCK_PHALCON_VERSION}/build \
    && ./install \
    && mv /usr/local/etc/php/conf.d/phalcon.ini.disable /usr/local/etc/php/conf.d/phalcon.ini \
    && rm -rf /tmp/cphalcon* \
;fi

###########################################################################
# APCU:
###########################################################################

ARG INSTALL_APCU=true

RUN if [ ${INSTALL_APCU} = true ]; then \
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
        pecl install -a apcu-4.0.11; \
    else \
        pecl install apcu; \
    fi && \
    docker-php-ext-enable apcu \
;fi

###########################################################################
# YAML:
###########################################################################

USER root

ARG INSTALL_YAML=false

RUN if [ ${INSTALL_YAML} = true ]; then \
    apt-get install -yqq libyaml-dev; \
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
        echo '' | pecl install -a yaml-1.3.2; \
    elif [ $(php -r "echo PHP_MAJOR_VERSION;") = "7" ] && [ $(php -r "echo PHP_MINOR_VERSION;") = "0" ]; then \
        echo '' | pecl install yaml-2.0.4; \
    else \
        echo '' | pecl install yaml; \
    fi \
    && docker-php-ext-enable yaml \
;fi

###########################################################################
# RDKAFKA:
###########################################################################

ARG INSTALL_RDKAFKA=false

RUN if [ ${INSTALL_RDKAFKA} = true ]; then \
    apt-get install -yqq librdkafka-dev && \
    pecl install rdkafka && \
    docker-php-ext-enable rdkafka \
;fi

###########################################################################
# GETTEXT:
###########################################################################

ARG INSTALL_GETTEXT=true

RUN if [ ${INSTALL_GETTEXT} = true ]; then \
    apt-get install -yqq zlib1g-dev libicu-dev g++ libpq-dev libssl-dev gettext && \
    docker-php-ext-install gettext \
;fi

###########################################################################
# Install additional locales:
###########################################################################

ARG INSTALL_ADDITIONAL_LOCALES=false
ARG ADDITIONAL_LOCALES

RUN if [ ${INSTALL_ADDITIONAL_LOCALES} = true ]; then \
    apt-get install -yqq locales \
    && echo '' >> /usr/share/locale/locale.alias \
    && temp="${ADDITIONAL_LOCALES%\"}" \
    && temp="${temp#\"}" \
    && for i in ${temp}; do sed -i "/$i/s/^#//g" /etc/locale.gen; done \
    && locale-gen \
;fi

###########################################################################
# MySQL Client:
###########################################################################

USER root

ARG INSTALL_MYSQL_CLIENT=true

RUN if [ ${INSTALL_MYSQL_CLIENT} = true ]; then \
      apt-get -y install default-mysql-client \
;fi

###########################################################################
# ping:
###########################################################################

USER root

ARG INSTALL_PING=false

RUN if [ ${INSTALL_PING} = true ]; then \
    apt-get -y install inetutils-ping \
;fi

###########################################################################
# sshpass:
###########################################################################

USER root

ARG INSTALL_SSHPASS=true

RUN if [ ${INSTALL_SSHPASS} = true ]; then \
    apt-get -y install sshpass \
;fi

###########################################################################
# Docker Client:
###########################################################################

USER root

ARG INSTALL_DOCKER_CLIENT=false

RUN if [ ${INSTALL_DOCKER_CLIENT} = true ]; then \
    curl -sS https://download.docker.com/linux/static/stable/x86_64/docker-20.10.3.tgz -o /tmp/docker.tar.gz && \
    tar -xzf /tmp/docker.tar.gz -C /tmp/ && \
    cp /tmp/docker/docker* /usr/local/bin && \
    chmod +x /usr/local/bin/docker* \
;fi

###########################################################################
# FFMPEG:
###########################################################################

USER root

ARG INSTALL_FFMPEG=false

RUN if [ ${INSTALL_FFMPEG} = true ]; then \
    apt-get -y install ffmpeg \
;fi

###########################################################################
# BBC Audio Waveform Image Generator:
###########################################################################

USER root

ARG INSTALL_AUDIOWAVEFORM=false

RUN if [ ${INSTALL_AUDIOWAVEFORM} = true ]; then \
    apt-get -y install wget make cmake gcc g++ libmad0-dev libid3tag0-dev libsndfile1-dev libgd-dev libboost-filesystem-dev libboost-program-options-dev libboost-regex-dev \
    && cd /tmp \
    && git clone https://github.com/bbc/audiowaveform.git \
    && cd audiowaveform \
    && git clone --depth=1 https://github.com/google/googletest.git -b release-1.11.0 \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make \
    && make install \
;fi


#####################################
# wkhtmltopdf:
#####################################

USER root

ARG INSTALL_WKHTMLTOPDF=false

RUN if [ ${INSTALL_WKHTMLTOPDF} = true ]; then \
    apt-get install -yqq \
      libxrender1 \
      libfontconfig1 \
      libx11-dev \
      libjpeg62 \
      libxtst6 \
      fontconfig \
      libjpeg62-turbo \
      xfonts-base \
      xfonts-75dpi \
      wget \
    && wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.stretch_amd64.deb \
    && dpkg -i wkhtmltox_0.12.6-1.stretch_amd64.deb \
    && apt -f install \
;fi

#####################################
# trader:
#####################################

USER root

ARG INSTALL_TRADER=false

RUN if [ ${INSTALL_TRADER} = true ]; then \
    pecl install trader \
    && echo "extension=trader.so" >> $PHP_INI_DIR/conf.d/trader.ini \
;fi

###########################################################################
# Mailparse extension:
###########################################################################

ARG INSTALL_MAILPARSE=false

RUN if [ ${INSTALL_MAILPARSE} = true ]; then \
    # Install mailparse extension
    printf "\n" | pecl install -o -f mailparse \
    &&  rm -rf /tmp/pear \
    &&  docker-php-ext-enable mailparse \
;fi

###########################################################################
# CacheTool:
###########################################################################

ARG INSTALL_CACHETOOL=false

RUN if [ ${INSTALL_CACHETOOL} = true ]; then \
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "7" ] && [ $(php -r "echo PHP_MINOR_VERSION;") -ge 1 ]; then \
            curl -sO http://gordalina.github.io/cachetool/downloads/cachetool.phar; \
    else \
        curl http://gordalina.github.io/cachetool/downloads/cachetool-3.2.1.phar -o cachetool.phar; \
    fi && \
    chmod +x cachetool.phar && \
    mv cachetool.phar /usr/local/bin/cachetool \
;fi

###########################################################################
# XMLRPC:
###########################################################################

ARG INSTALL_XMLRPC=false

RUN if [ ${INSTALL_XMLRPC} = true ]; then \
  apt-get -yq install libxml2-dev; \
  if [ $(php -r "echo PHP_MAJOR_VERSION;") = "8" ]; then \
    pecl install xmlrpc-1.0.0RC2; \
    docker-php-ext-enable xmlrpc; \
  else \
    docker-php-ext-install xmlrpc; \
  fi \
;fi

###########################################################################
# PHP DECIMAL:
###########################################################################

USER root

ARG INSTALL_PHPDECIMAL=false

RUN if [ ${INSTALL_PHPDECIMAL} = true ]; then \
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
      echo 'decimal not support PHP 5.6'; \
    else \
      apt-get install -yqq libmpdec-dev \
      && pecl install decimal \
      && docker-php-ext-enable decimal \
      && php -m | grep -q 'decimal' \
    ;fi \
;fi

###########################################################################
# zookeeper
###########################################################################
ARG INSTALL_ZOOKEEPER=false

RUN set -eux; \
    if [ ${INSTALL_ZOOKEEPER} = true ]; then \
    apt install -yqq libzookeeper-mt-dev; \
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "8" ]; then \
      curl -L -o /tmp/php-zookeeper.tar.gz https://github.com/php-zookeeper/php-zookeeper/archive/master.tar.gz; \
      mkdir -p /tmp/php-zookeeper; \
      tar -C /tmp/php-zookeeper -zxvf /tmp/php-zookeeper.tar.gz --strip 1; \
      cd /tmp/php-zookeeper; \
      phpize && ./configure && make && make install;\
    else \
      if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
        pecl install zookeeper-0.5.0; \
      else \
        pecl install zookeeper-0.7.2; \
      fi; \
    fi; \
    docker-php-ext-enable zookeeper; \
    php -m | grep -q 'zookeeper'; \
    fi

###########################################################################
# New Relic for PHP:
###########################################################################
ARG NEW_RELIC=${NEW_RELIC}
ARG NEW_RELIC_KEY=${NEW_RELIC_KEY}
ARG NEW_RELIC_APP_NAME=${NEW_RELIC_APP_NAME}

RUN if [ ${NEW_RELIC} = true ]; then \
  curl -L http://download.newrelic.com/php_agent/archive/9.9.0.260/newrelic-php5-9.9.0.260-linux.tar.gz | tar -C /tmp -zx && \
  export NR_INSTALL_USE_CP_NOT_LN=1 && \
  export NR_INSTALL_SILENT=1 && \
  /tmp/newrelic-php5-*/newrelic-install install && \
  rm -rf /tmp/newrelic-php5-* /tmp/nrinstall* && \
  sed -i \
  -e 's/"REPLACE_WITH_REAL_KEY"/"'${NEW_RELIC_KEY}'"/' \
  -e 's/newrelic.appname = "PHP Application"/newrelic.appname = "'${NEW_RELIC_APP_NAME}'"/' \
  -e 's/;newrelic.daemon.app_connect_timeout =.*/newrelic.daemon.app_connect_timeout=15s/' \
  -e 's/;newrelic.daemon.start_timeout =.*/newrelic.daemon.start_timeout=5s/' \
  /usr/local/etc/php/conf.d/newrelic.ini \
;fi

###########################################################################
# PHP SSDB:
###########################################################################

USER root

ARG INSTALL_SSDB=false

RUN set -xe; \
    if [ ${INSTALL_SSDB} = true ] && [ $(php -r "echo PHP_MAJOR_VERSION;") != "8" ]; then \
    apt-get -y install sudo wget && \
    if [ $(php -r "echo PHP_MAJOR_VERSION;") = "7" ]; then \
      curl -L -o /tmp/ssdb-client-php.tar.gz https://github.com/jonnywang/phpssdb/archive/php7.tar.gz; \
    else \
      curl -L -o /tmp/ssdb-client-php.tar.gz https://github.com/jonnywang/phpssdb/archive/master.tar.gz; \
    fi \
    && mkdir -p /tmp/ssdb-client-php \
    && tar -C /tmp/ssdb-client-php -zxvf /tmp/ssdb-client-php.tar.gz --strip 1 \
    && cd /tmp/ssdb-client-php \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && rm /tmp/ssdb-client-php.tar.gz \
    && docker-php-ext-enable ssdb \
;fi
###########################################################################
# Downgrade Openssl:
###########################################################################

ARG DOWNGRADE_OPENSSL_TLS_AND_SECLEVEL=true

RUN if [ ${DOWNGRADE_OPENSSL_TLS_AND_SECLEVEL} = true ]; then \
    sed -i 's,^\(MinProtocol[ ]*=\).*,\1'TLSv1.2',g' /etc/ssl/openssl.cnf \
    && \
    sed -i 's,^\(CipherString[ ]*=\).*,\1'DEFAULT@SECLEVEL=1',g' /etc/ssl/openssl.cnf\
;fi

###########################################################################
# Check PHP version:
###########################################################################

RUN set -xe; php -v | head -n 1 | grep -q "PHP ${LARADOCK_PHP_VERSION}."

#
#--------------------------------------------------------------------------
# Final Touch
#--------------------------------------------------------------------------
#

# COPY ./laravel.ini /usr/local/etc/php/conf.d
# COPY ./xlaravel.pool.conf /usr/local/etc/php-fpm.d/

USER root

RUN curl https://getcomposer.org/installer > composer-setup.php \
    && php composer-setup.php \
    && mv composer.phar /usr/local/bin/composer \
    && rm composer-setup.php

# Clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm /var/log/lastlog /var/log/faillog

# Configure non-root user.
ARG PUID=1000
ENV PUID ${PUID}
ARG PGID=1000
ENV PGID ${PGID}

RUN groupmod -o -g ${PGID} www-data && \
    usermod -o -u ${PUID} -g www-data www-data

# Adding the faketime library to the preload file needs to be done last
# otherwise it will preload it for all commands that follow in this file
RUN if [ ${INSTALL_FAKETIME} = true ]; then \
    echo "/usr/lib/x86_64-linux-gnu/faketime/libfaketime.so.1" > /etc/ld.so.preload \
;fi

# Configure locale.
ARG LOCALE=POSIX
ENV LC_ALL ${LOCALE}

WORKDIR /var/app

CMD ["php-fpm"]

EXPOSE 9000