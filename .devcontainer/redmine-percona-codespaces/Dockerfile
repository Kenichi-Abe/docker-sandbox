# Redmine 4.1.1
# plugins/ と vendor/ をビルド時にイメージへ内包する
FROM redmine:4.1.1

USER root

# Debian 10 (buster) は EOL のため archive.debian.org を使う
RUN set -eux; \
    printf '%s\n' \
      'deb http://archive.debian.org/debian buster main' \
      'deb http://archive.debian.org/debian buster-updates main' \
      'deb http://archive.debian.org/debian-security buster/updates main' \
      > /etc/apt/sources.list; \
    rm -f /etc/apt/sources.list.d/*; \
    apt-get -o Acquire::Check-Valid-Until=false update; \
    apt-get -o Acquire::Check-Valid-Until=false install -y --no-install-recommends \
        gcc \
        make \
        patch \
        pkg-config \
        libmariadbclient-dev \
        libpq-dev \
        libsqlite3-dev \
        libxml2-dev \
        libxslt1-dev \
        zlib1g-dev \
        git \
    ; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/redmine

COPY plugins/ /usr/src/redmine/plugins/
COPY vendor/  /usr/src/redmine/vendor/
COPY themes/  /usr/src/redmine/public/themes/

ENV BUNDLE_WITHOUT="development:test" \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

RUN set -eux; \
    mkdir -p /usr/src/redmine/vendor/bundle \
             /usr/src/redmine/public/plugin_assets \
             /usr/src/redmine/tmp/pids \
             /usr/src/redmine/tmp/pdf \
             /usr/src/redmine/log; \
    if [ -d /usr/src/redmine/vendor/bundle ] && [ "$(find /usr/src/redmine/vendor/bundle -name '*.gemspec' | head -n 1)" ]; then \
        echo "vendor/bundle を検出したので --path vendor/bundle でインストールします"; \
        gosu redmine bundle config set --local path 'vendor/bundle'; \
    fi; \
    if [ -f /usr/src/redmine/config/database.yml ]; then \
        :; \
    else \
        printf '%s\n' 'production:' '  adapter: mysql2' > /usr/src/redmine/config/database.yml; \
    fi; \
    gosu redmine bundle install --without development test; \
    rm -f /usr/src/redmine/config/database.yml; \
    chown -R redmine:redmine \
        /usr/src/redmine/plugins \
        /usr/src/redmine/vendor \
        /usr/src/redmine/public/themes \
        /usr/src/redmine/public/plugin_assets \
        /usr/src/redmine/tmp \
        /usr/src/redmine/log \
        /usr/src/redmine/Gemfile.lock \
        /usr/src/redmine/.bundle || true; \
    chmod -R ugo=rwX /usr/src/redmine/plugins /usr/src/redmine/vendor /usr/src/redmine/public/themes

USER redmine

EXPOSE 3000