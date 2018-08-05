FROM ubuntu AS build

ENV DEBIAN_FRONTEND=noninteractive
ARG REPO=cryptozeny/bitzeny
ARG REF=yespower-0.5
ARG BINARY=bitzeny
ARG JOBS=2
ARG BTC_DEPENDS_VER=0.16.1

RUN mkdir /logs && mv /bin/sh /bin/sh.bak && ln -s /bin/bash /bin/sh

RUN ( apt-get update -qq && \
    apt-get upgrade -y -qq && \
    apt-get install -y -qq build-essential \
      libtool autotools-dev autoconf \
      pkg-config \
      software-properties-common \
      git wget curl bsdmainutils \
      g++-mingw-w64-x86-64 tar && \
    echo 1 | update-alternatives --config x86_64-w64-mingw32-g++ && \
    add-apt-repository -y ppa:bitcoin/bitcoin && \
    apt-get update -qq && \
    apt-get install -y -qq libdb4.8-dev libdb4.8++-dev && \
    git clone https://github.com/${REPO}.git /${BINARY} ) 2>&1 | tee /logs/setup.txt | wc -l

WORKDIR /${BINARY}

RUN git checkout "$REF" && \
    rm -rf depends/ && \
    wget -qO- https://github.com/bitcoin/bitcoin/archive/v${BTC_DEPENDS_VER}.tar.gz | tar -xvzf - --strip-components=1 --wildcards '*/depends' | wc -l && \
    wget -qO depends/packages/qt.mk https://github.com/bitcoin/bitcoin/raw/master/depends/packages/qt.mk && \
    wget -qO depends/patches/qt/fix_configure_mac.patch https://github.com/bitcoin/bitcoin/raw/master/depends/patches/qt/fix_configure_mac.patch && \
    wget -qO depends/patches/qt/fix_no_printer.patch https://github.com/bitcoin/bitcoin/raw/master/depends/patches/qt/fix_no_printer.patch && \
    wget -qO depends/patches/qt/fix_rcc_determinism.patch https://github.com/bitcoin/bitcoin/raw/master/depends/patches/qt/fix_rcc_determinism.patch

WORKDIR depends

RUN set -o pipefail && \
    make HOST=x86_64-w64-mingw32 -j${JOBS} 2>&1 | grep -v '^$' | tee /logs/depends.txt | wc -l || ( cat /logs/depends.txt && false )

WORKDIR ..

RUN set -o pipefail && \
    ( ./autogen.sh && \
    CONFIG_SITE=depends/x86_64-w64-mingw32/share/config.site  \
      ./configure --without-miniupnpc --disable-tests \
      --with-boost=depends/x86_64-w64-mingw32/include/boost/ \
      --with-qt-bindir=depends/x86_64-w64-mingw32/bin && \
    make -j${JOBS} ) 2>&1 | tee /logs/main.txt || ( cat config.log && false )

RUN ls src
