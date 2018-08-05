# CC0

FROM ubuntu AS build

ENV DEBIAN_FRONTEND=noninteractive

# modify following ARGs to compile another variant
ARG REPO=bitzenyPlus/BitZenyPlus
ARG REF=feature/yespower-0.5
ARG BINARY=bitzeny
ARG JOBS=2

# needed for "set -o pipefail"
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
    git clone https://github.com/${REPO}.git /${BINARY} -b ${REF} --depth=1 ) 2>&1 | tee /logs/setup.txt | wc -l

WORKDIR /${BINARY}/depends

RUN set -o pipefail && \
    make HOST=x86_64-w64-mingw32 -j${JOBS} 2>&1 | grep -v '^$' | tee /logs/depends.txt | wc -l || ( cat /logs/depends.txt && false )

WORKDIR ..

RUN set -o pipefail && \
    ( ./autogen.sh && \
    CONFIG_SITE=$PWD/depends/x86_64-w64-mingw32/share/config.site  \
      ./configure --without-miniupnpc --disable-tests --disable-bench && \
    make -j${JOBS} ) 2>&1 | tee /logs/main.txt || ( cat config.log && false )

RUN ls src
