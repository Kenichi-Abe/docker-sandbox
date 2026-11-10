FROM docker.io/library/redmine:7.0.3

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
