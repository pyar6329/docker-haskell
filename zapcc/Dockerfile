# syntax=docker/dockerfile:1.0-experimental
FROM ubuntu:20.04 as build-zapcc

ENV LANG="C.UTF-8" \
    LC_ALL="C.UTF-8" \
    DEBIAN_FRONTEND=noninteractive

## install stack

ARG LLVM_VERSION=7
ARG CC=/usr/bin/clang 
ARG CXX=/usr/bin/clang++ 

WORKDIR /workdir

RUN set -x && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    zstd \
    git \
    curl \
    make \
    ninja-build \
    cmake \
    ocaml \
    python3 \
    python3-pip \
    lbzip2 \
    ca-certificates \
    lld-${LLVM_VERSION} \
    clang-${LLVM_VERSION} \
    llvm-${LLVM_VERSION} \
    llvm-${LLVM_VERSION}-dev \
    libomp-dev \
    llvm-${LLVM_VERSION}-tools && \
  pip3 install pygments pyyaml && \
  update-alternatives --install "/usr/bin/clang" "clang" "/usr/bin/clang-${LLVM_VERSION}" 10 && \
  update-alternatives --install "/usr/bin/clang++" "clang++" "/usr/bin/clang++-${LLVM_VERSION}" 10 && \
  update-alternatives --install "/usr/bin/cc" "cc" "/usr/bin/clang" 10 && \
  update-alternatives --install "/usr/bin/c++" "c++" "/usr/bin/clang++"

RUN set -x && \
  git clone https://github.com/yrnkrn/zapcc.git llvm && \
  mkdir build && \
  cd build && \
  cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_WARNINGS=OFF ../llvm && \
  ninja

RUN set -x && \
  mkdir -p /dist/zapcc-ubuntu-20.04/lib && \
  cp -rf /workdir/build/lib/*.so* /dist/zapcc-ubuntu-20.04/lib && \
  cp -rf /workdir/build/bin /dist/zapcc-ubuntu-20.04/bin && \
  cd /dist && \
  tar -I "pzstd -19" -cvf zapcc-ubuntu-20.04.tar.zst zapcc-ubuntu-20.04

FROM ubuntu:20.04 

WORKDIR /dist

COPY --from=build-zapcc /dist/zapcc-ubuntu-20.04.tar.zst /dist/zapcc-ubuntu-20.04.tar.zst
