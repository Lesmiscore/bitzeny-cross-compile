FROM ubuntu AS build

ENV DEBIAN_FRONTEND=noninteractive
ARG REPO=cryptozeny/bitzeny
ARG REF=yespower-0.5
ARG BINARY=bitzeny
ARG JOBS=2

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y build-essential \
      libtool autotools-dev autoconf \
      libssl-dev \
      libboost-all-dev \
      libevent-dev \
      pkg-config \
      software-properties-common \
      git wget bsdmainutils \
      g++-mingw-w64-x86-64 unzip && \
    update-alternatives --config x86_64-w64-mingw32-g++ && \
    add-apt-repository -y ppa:bitcoin/bitcoin && \
    apt-get update && \
    apt-get install -y libdb4.8-dev libdb4.8++-dev && \
    git clone https://github.com/${REPO}.git /${BINARY}

RUN wget https://github.com/bitcoin/bitcoin/archive/master.zip -O /bitcoin-master.zip

WORKDIR /${BINARY}

RUN git checkout "$REF" && \
    rm -rf depends/ && \
    unzip /bitcoin-master.zip 'depends/*' -d depends/

WORKDIR depends

RUN make HOST=x86_64-w64-mingw32 -j${JOBS}

WORKDIR ..

RUN ./autogen.sh && \
    CONFIG_SITE=depends/x86_64-w64-mingw32/share/config.site  ./configure --without-miniupnpc --disable-tests && \
    make -j${JOBS}

RUN ls
