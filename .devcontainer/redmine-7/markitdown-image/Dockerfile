FROM docker.io/library/redmine:7.0.3

COPY Gemfile.local /usr/src/redmine/Gemfile.local
COPY plugins/ /usr/src/redmine/plugins/
COPY patches/redmine_omniauth_oidc_login_case.patch /tmp/redmine_omniauth_oidc_login_case.patch
COPY patches/redmine_omniauth_oidc_http_discovery.patch /tmp/redmine_omniauth_oidc_http_discovery.patch
COPY patches/redmine_omniauth_oidc_full_host_protocol.patch /tmp/redmine_omniauth_oidc_full_host_protocol.patch

RUN if [ -f plugins/redmine_omniauth_oidc/initializers/redmine_omniauth_oidc.rb ]; then \
        install -m 0644 \
            plugins/redmine_omniauth_oidc/initializers/redmine_omniauth_oidc.rb \
            config/initializers/redmine_omniauth_oidc.rb; \
    fi

ARG PANDOC_VERSION=3.13
ARG PANDOC_DEB_SHA256=7e3736f255090296ca5d1a14291a76b9b3c43cd385011b1621a4d0c16091a70f

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 python3-venv \
    && python3 -c 'import sys; assert sys.version_info >= (3, 10), sys.version' \
    && python3 -m venv /opt/markitdown-venv \
    && /opt/markitdown-venv/bin/python -m pip install --no-cache-dir uv \
    && /opt/markitdown-venv/bin/uv pip install \
        --python /opt/markitdown-venv/bin/python \
        'markitdown[pdf,docx,pptx,xlsx,xls]' \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="/opt/markitdown-venv/bin:${PATH}"

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends wget; \
    wget -O /tmp/pandoc.deb \
        "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-1-amd64.deb"; \
    echo "${PANDOC_DEB_SHA256}  /tmp/pandoc.deb" | sha256sum --check --strict; \
    apt-get install -y --no-install-recommends /tmp/pandoc.deb; \
    rm -rf /tmp/pandoc.deb /var/lib/apt/lists/*

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends build-essential patch pkg-config; \
    patch --batch --forward -p1 -d /usr/src/redmine/plugins/redmine_omniauth_oidc < /tmp/redmine_omniauth_oidc_login_case.patch; \
    patch --batch --forward -p1 -d /usr/src/redmine/plugins/redmine_omniauth_oidc < /tmp/redmine_omniauth_oidc_full_host_protocol.patch; \
    patch --batch --forward -p1 -d /usr/src/redmine < /tmp/redmine_omniauth_oidc_http_discovery.patch; \
    rm /tmp/redmine_omniauth_oidc_login_case.patch /tmp/redmine_omniauth_oidc_http_discovery.patch /tmp/redmine_omniauth_oidc_full_host_protocol.patch; \
        echo '# Temporary adapter entries ensure plugin and database adapter gems are resolved during image build.' > /usr/src/redmine/config/database.yml; \
        for adapter in mysql2 postgresql sqlserver sqlite3; do \
            printf '%s:\n  adapter: %s\n' "$adapter" "$adapter" >> /usr/src/redmine/config/database.yml; \
        done; \
    gosu redmine bundle check || gosu redmine bundle install --jobs "$(nproc)"; \
    gosu redmine bundle check; \
        rm /usr/src/redmine/config/database.yml; \
    apt-get purge -y --auto-remove build-essential patch pkg-config; \
    rm -rf /var/lib/apt/lists/*
