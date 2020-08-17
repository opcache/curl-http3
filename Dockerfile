FROM ubuntu:18.04 AS builder

LABEL maintainer="Yury Muski <muski.yury@gmail.com>"

WORKDIR /opt

RUN apt-get update && \
    apt-get install -y build-essential git autoconf libtool pkg-config cmake golang-go && \
    apt-get purge -y curl;

# https://github.com/curl/curl/blob/master/docs/HTTP3.md#quiche-version

# build boring ssl
RUN git clone --recursive https://github.com/cloudflare/quiche
RUN cd quiche/deps/boringssl && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_POSITION_INDEPENDENT_CODE=on .. && \
    make && \
    cd .. && \
    mkdir -p .openssl/lib
   
