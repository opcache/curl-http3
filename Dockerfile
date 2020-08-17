FROM ubuntu:18.04 AS builder

LABEL maintainer="Yury Muski <muski.yury@gmail.com>"

WORKDIR /opt

RUN apt-get update && \
    apt-get install -y build-essential git autoconf libtool libssl-dev cmake golang-go curl;

# https://github.com/curl/curl/blob/master/docs/HTTP3.md#quiche-version

# build boring ssl
RUN git clone --recursive https://github.com/cloudflare/quiche
RUN cd quiche/deps/boringssl && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_POSITION_INDEPENDENT_CODE=on .. && \
    make && \
    cd .. && \
    mkdir -p .openssl/lib && \
    cp build/libcrypto.a build/libssl.a .openssl/lib && \
    ln -s /opt/quiche/deps/boringssl/include /opt/quiche/deps/boringssl/.openssl

# install rust & cargo
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y -q;

# build quiche:
RUN export PATH="$HOME/.cargo/bin:$PATH" && \
    cd quiche && \
    QUICHE_BSSL_PATH=$PWD/deps/boringssl cargo build --release --features pkg-config-meta,qlog




FROM ubuntu:bionic
RUN apt-get update && apt-get install -y curl

COPY --from=builder /ubuntu/usr/local/ /usr/local/
COPY --from=builder /opt/quiche/target/release /opt/quiche/target/release
COPY --from=builder /opt/quiche/deps/boringssl/.openssl /opt/quiche/deps/boringssl/.openssl

# Resolve any issues of C-level lib
# location caches ("shared library cache")
RUN ldconfig

WORKDIR /opt
# add httpstat script
RUN curl -s https://raw.githubusercontent.com/b4b4r07/httpstat/master/httpstat.sh >httpstat.sh && chmod +x httpstat.sh

CMD ["curl"]
