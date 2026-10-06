FROM --platform=linux/amd64 python:3.9-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    MECABRC=/etc/mecabrc

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        build-essential \
        curl \
        diffutils \
        file \
        git \
        libgomp1 \
        mecab \
        libmecab-dev \
        mecab-ipadic-utf8 \
        openssl \
        patch \
        sudo \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

# ノートブックは /usr/lib/mecab/dic/mecab-ipadic-neologd を指定する。
RUN git clone --depth 1 https://github.com/neologd/mecab-ipadic-neologd.git /tmp/mecab-ipadic-neologd \
    && cd /tmp/mecab-ipadic-neologd \
    && bin/install-mecab-ipadic-neologd -y -p /usr/lib/mecab/dic/mecab-ipadic-neologd \
    && rm -rf /tmp/mecab-ipadic-neologd

COPY requirements.txt /tmp/requirements.txt
# gensim 3.8.3 には Python 3.9 向け wheel がない。
# ビルドを隔離すると NumPy 2 が入り、同梱の C 拡張がコンパイルに失敗する。
RUN pip install --no-cache-dir --default-timeout=300 --retries 10 \
        "numpy==1.21.6" "scipy==1.7.3" "smart_open==5.2.1" "six==1.17.0" \
    && pip install --no-cache-dir --default-timeout=300 --retries 10 \
        --no-build-isolation \
        "gensim==3.8.3" "numpy==1.21.6" "scipy==1.7.3" "smart_open==5.2.1" \
    && pip install --no-cache-dir --default-timeout=300 --retries 10 \
        -r /tmp/requirements.txt \
        --extra-index-url https://download.pytorch.org/whl/cpu \
    && rm /tmp/requirements.txt

COPY docker/entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh

WORKDIR /workspace
EXPOSE 8888

ENTRYPOINT ["/opt/entrypoint.sh"]
