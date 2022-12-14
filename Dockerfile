FROM composer:2.4.4 as composer

FROM php:8.1.12-alpine3.15 as build
COPY --from=composer /usr/bin/composer /usr/bin/composer
WORKDIR /app/
COPY app/ /app/
RUN chmod a+rx /usr/bin/composer && /usr/bin/composer install --no-interaction --no-scripts --no-progress --optimize-autoloader

FROM pipelinecomponents/base-entrypoint:0.5.0 as entrypoint

FROM php:8.1.12-alpine3.15

COPY --from=entrypoint /entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
ENV DEFAULTCMD phpunit

ENV PATH "$PATH:/app/vendor/bin/"
# hadolint ignore=DL3018
RUN apk add --no-cache 	curl \
    && apk add --virtual build-dependencies --no-cache build-base autoconf libxml2-dev  \
    && docker-php-source extract \
    && pecl install xdebug-3.1.2 \
    && docker-php-ext-enable xdebug \
    && docker-php-ext-install soap \
    && docker-php-ext-enable soap \
    && docker-php-source delete \
    && apk del build-dependencies \
    && pecl clear-cache \
    && rm -rf /tmp/pear

COPY --from=build /app/ /app/
COPY php.ini /usr/local/etc/php/php.ini

WORKDIR /code/
# Build arguments
ARG BUILD_DATE
ARG BUILD_REF

# Labels
LABEL \
    maintainer="Robbert Müller <dev@pipeline-components.dev>" \
    org.label-schema.description="PHPUnit in a container for gitlab-ci" \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.name="PHPUnit" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.url="https://pipeline-components.gitlab.io/" \
    org.label-schema.usage="https://gitlab.com/pipeline-components/phpunit/blob/master/README.md" \
    org.label-schema.vcs-ref=${BUILD_REF} \
    org.label-schema.vcs-url="https://gitlab.com/pipeline-components/phpunit/" \
    org.label-schema.vendor="Pipeline Components"
