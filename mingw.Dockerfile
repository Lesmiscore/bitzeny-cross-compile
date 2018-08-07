# CC0
ARG PARENT=ubuntu
FROM ${PARENT} AS build

ENV DEBIAN_FRONTEND=noninteractive

# modify following ARGs to compile another variant
ARG REPO=bitzenyPlus/BitZenyPlus
ARG REF=v3.0-dev
ARG BINARY=bitzeny
ARG JOBS=2

# needed for "set -o pipefail"
RUN mkdir /logs && mv /bin/sh /bin/sh.bak && ln -s /bin/bash /bin/sh

RUN set -o pipefail && \
    ( apt-get update -qq && \
    apt-get upgrade -y -qq && \
    apt-get install -y -qq build-essential \
      libtool autotools-dev autoconf \
      pkg-config tree zip \
      git curl bsdmainutils \
      g++-mingw-w64-x86-64 tar && \
    ( which x86_64-w64-mingw32-g++-posix && update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix || true ) && \
    git clone https://github.com/${REPO}.git /${BINARY} ) 2>&1 | tee /logs/setup.txt | wc -l \
    || ( cat /logs/setup.txt && false )

WORKDIR /${BINARY}

RUN git checkout ${REF}

WORKDIR depends

RUN set -o pipefail && \
    make HOST=x86_64-w64-mingw32 -j${JOBS} 2>&1 | grep -v '^$' | tee /logs/depends.txt | wc -l || ( cat /logs/depends.txt && false )

WORKDIR ..

RUN set -o pipefail && mkdir root && \
    ( ./autogen.sh && \
    CONFIG_SITE=$PWD/depends/x86_64-w64-mingw32/share/config.site  \
      ./configure --without-miniupnpc --disable-tests --disable-bench \
      --prefix=$PWD/root && \
    make -j${JOBS} && make install ) 2>&1 | tee /logs/main.txt || ( cat config.log && false )

RUN ( tree -fai root/ | grep '\.exe$' | sort | xargs ls -l --block-size=M ) && \
    ( tree -fai root/ | grep '\.exe$' | sort | xargs x86_64-w64-mingw32-strip ; echo ) && \
    ( tree -fai root/ | grep '\.exe$' | sort | xargs ls -l --block-size=M ) 

RUN zip -9 -X -r bin.zip root/
