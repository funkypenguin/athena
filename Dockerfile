FROM debian:9 as builder

# install build dependencies
# checkout the latest tag
# build and install
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      gdb \
      libreadline-dev \
      python-dev \
      gcc \
      g++\
      git \
      cmake \
      libboost-all-dev \
      librocksdb-dev && \
    git clone https://github.com/athena-network/athena.git /opt/athena && \
    cd /opt/athena && \
    mkdir build && \
    cd build && \
    export CXXFLAGS="-w -std=gnu++11" && \
    #cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo .. && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="-fassociative-math" -DCMAKE_CXX_FLAGS="-fassociative-math" -DSTATIC=true -DDO_TESTS=OFF .. && \
    make -j$(nproc)

FROM debian:9

# Athena now needs libreadline 
RUN apt-get update && \
    apt-get install -y \
      libreadline-dev \
     && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/bin && mkdir -p /tmp/checkpoints 

WORKDIR /usr/local/bin
COPY --from=builder /opt/athena/build/src/Athena .
COPY --from=builder /opt/athena/build/src/wallet .
COPY --from=builder /opt/athena/build/src/solominer .
RUN mkdir -p /var/lib/athena
WORKDIR /var/lib/athena
ENTRYPOINT ["/usr/local/bin/Athena"]
CMD ["--no-console","--data-dir","/var/lib/athena","--rpc-bind-ip","0.0.0.0","--rpc-bind-port","11898","--p2p-bind-port","11897","--enable-cors=*","--enable_blockexplorer"]
