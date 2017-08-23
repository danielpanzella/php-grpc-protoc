FROM ubuntu:xenial
ENV DEBIAN_FRONTEND noninteractive
COPY docker/conf/sources.list /etc/apt/sources.list

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E5267A6C && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys DC6A13A3 && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 56A3D45E  && \
    apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y \
            golang-1.8 \
            wget \
            unzip \
            composer \
            zlib1g-dev \
            php-cli \
            php-dev \
            php-pear && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /root
RUN wget https://github.com/google/protobuf/releases/download/v3.3.0/protoc-3.3.0-linux-x86_64.zip && \
    mkdir protoc && cd protoc && \
    unzip ../protoc-3.3.0-linux-x86_64.zip && \
    cd ../ && mv protoc /opt/protoc && \
    echo 'eval `/usr/lib/go-1.8/bin/go env`' >> ~/.bashrc && \
    echo "PATH=$GOPATH/bin:$GOROOT/bin:$PATH:/opt/protoc/bin" >> ~/.bashrc

RUN pecl install grpc
RUN git clone --recursive -b v1.4.x https://github.com/grpc/grpc /root/grpc && \
    cd /root/grpc && \
    make grpc_php_plugin && \
    cp /root/grpc/bins/opt/grpc_php_plugin /usr/local/bin/ && \
    cd /usr/local/bin/ && \
    ln -s grpc_php_plugin protoc-gen-grpc

RUN /usr/lib/go-1.8/bin/go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway

COPY docker/conf/grpc.php.ini /etc/php/7.0/cli/conf.d/grpc.ini

CMD GOPATH=/root/go/ GOROOT=/usr/lib/go-1.8/ PATH=$GOPATH/bin:$GOROOT/bin:$PATH:/opt/protoc/bin protoc -Iproto -I$GOPATH/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis --php_out=src --grpc_out=src proto/*
