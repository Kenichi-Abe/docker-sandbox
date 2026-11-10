FROM docker.io/library/redmine:7.0.3

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
