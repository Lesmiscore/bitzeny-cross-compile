FROM ubuntu AS build

ENV DEBIAN_FRONTEND=noninteractive
ARG REPO=cryptozeny/bitzeny
ARG REF=yespower-0.5
ARG BINARY=bitzeny
ARG JOBS=2

RUN mkdir /logs && mv /bin/sh /bin/sh.bak && ln -s /bin/bash /bin/sh

RUN ( apt-get update -qq && \
    apt-get upgrade -y -qq && \
    apt-get install -y -qq build-essential \
      libtool autotools-dev autoconf \
      pkg-config \
      software-properties-common \
      git wget curl bsdmainutils \
      g++-mingw-w64-x86-64 tar \
      qtbase5-dev-tools qtbase5-dev && \
    echo 1 | update-alternatives --config x86_64-w64-mingw32-g++ && \
    add-apt-repository -y ppa:bitcoin/bitcoin && \
    apt-get update -qq && \
    apt-get install -y -qq libdb4.8-dev libdb4.8++-dev && \
    git clone https://github.com/${REPO}.git /${BINARY} ) 2>&1 | tee /logs/setup.txt | wc -l

WORKDIR /${BINARY}

RUN git checkout "$REF" && \
    rm -rf depends/ && \
    wget -qO- https://github.com/bitcoin/bitcoin/archive/v0.16.1.tar.gz | tar -xvzf - --strip-components=1 --wildcards '*/depends' | wc -l

RUN wget -qO- https://gist.github.com/nao20010128nao/1b8220c451308683e4f82b7c2ad5f1e2/raw/3677355c2f898790e67fa04461297f42e3221114/bitcoin-qt.diff | patch -p1

WORKDIR depends

RUN set -o pipefail && \
    make HOST=x86_64-w64-mingw32 -j${JOBS} 2>&1 | grep -v '^$' | tee /logs/depends.txt | wc -l

WORKDIR ..

RUN set -o pipefail && \
    ( ./autogen.sh && \
    CONFIG_SITE=depends/x86_64-w64-mingw32/share/config.site  ./configure --without-miniupnpc --disable-tests && \
    make -j${JOBS} ) 2>&1 | tee /logs/main.txt

RUN ls src
