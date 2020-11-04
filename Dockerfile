FROM alpine:3.9
LABEL Maintainer="eratechid" \
      Description="Lightweight container with Nginx 1.14 & PHP-FPM 7.2 based on Alpine Linux."

ENV TZ "Asia/Jakarta"
ARG NEW_RELIC_LICENSE_KEY
ARG APP_NAME

# Install packages
RUN apk update && \
    apk --no-cache add \
    bash tzdata curl mysql-client nginx supervisor \
    php7-intl php7-xmlreader php7-xmlwriter\
    php7 php7-phar php7-curl php7-fpm php7-json php7-zlib php7-gd \
    php7-xml php7-dom php7-ctype php7-opcache php7-zip php7-iconv \
    php7-pdo php7-pdo_mysql php7-mysqli php7-mbstring php7-session \
    php7-mcrypt php7-openssl php7-sockets php7-posix php7-tokenizer \
    php7-fileinfo php7-simplexml

RUN apk add --update nodejs npm
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
RUN ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime && \
echo "$TZ" > /etc/timezone


# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/conf.d/zzz_custom.ini

# Configure New Relic
COPY config/newrelic-20170718.so /usr/lib/php7/modules/newrelic.so
COPY config/newrelic-daemon.x64 /usr/bin/newrelic-daemon
COPY config/newrelic.ini.template /etc/php7/conf.d/newrelic.ini
RUN sed -i -e "s/REPLACE_WITH_REAL_KEY/${NEW_RELIC_LICENSE_KEY}/" /etc/php7/conf.d/newrelic.ini
RUN sed -i -e "s/REPLACE_WITH_REAL_APP/${APP_NAME}/" /etc/php7/conf.d/newrelic.ini
RUN mkdir -p  /var/log/newrelic

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
#RUN chown -R nobody.nobody /run && \
#  chown -R nobody.nobody /var/lib/nginx && \
#  chown -R nobody.nobody /var/tmp/nginx && \
#  chown -R nobody.nobody /var/log/nginx && \
#  chown -R nobody.nobody /var/log/newrelic

# Setup document root
RUN mkdir -p /var/www/html

# Switch to use a non-root user from here on
#USER nobody

# Add application
WORKDIR /var/www/html
#COPY --chown=nobody src/ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
#CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf", "&& newrelic-daemon start"]
CMD /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
