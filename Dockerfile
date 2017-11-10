FROM nginx

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY php-fpm.conf /usr/local/etc/php-fpm.conf

ADD php-5.5.38.tar.gz /usr/

ENV PHP_EXTRA_CONFIGURE_ARGS --enable-fpm --with-fpm-user=nginx --with-fpm-group=nginx
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"
ENV PHP_VERSION 5.5.38

ENV PHP_INI_DIR /usr/local/etc/php
RUN mkdir -p $PHP_INI_DIR/conf.d && mkdir -p /var/log/php-fpm && mkdir /var/run/php-fpm/

RUN apt-get update && apt-get install -y build-essential libxml2-dev curl libc-dev pkgconf re2c openssl libedit-dev libcurl4-gnutls-dev \
  && cd /usr/local/include && ln -s /usr/include/x86_64-linux-gnu/curl curl \
  && cd /usr/php-5.5.38 \
  && export CFLAGS="$PHP_CFLAGS" \
		CPPFLAGS="$PHP_CPPFLAGS" \
		LDFLAGS="$PHP_LDFLAGS" \
  && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
  && ./configure \
		--build="$gnuArch" \
		--with-config-file-path="$PHP_INI_DIR" \
		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
		--disable-cgi \
# --enable-ftp is included here because ftp_ssl_connect() needs ftp to be compiled statically (see https://github.com/docker-library/php/issues/236)
		--enable-ftp \
# --enable-mbstring is included here because otherwise there's no way to get pecl to use it properly (see https://github.com/docker-library/php/issues/195)
		--enable-mbstring \
# --enable-mysqlnd is included here because it's harder to compile after the fact than extensions are (since it's a plugin for several extensions, not an extension in itself)
        --with-mysqli \
		--with-curl \
		--with-libedit \
		$PHP_EXTRA_CONFIGURE_ARGS \
  && make -j "$(nproc)" \
  && make install \
  && make clean

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]