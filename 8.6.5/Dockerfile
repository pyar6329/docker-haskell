# syntax=docker/dockerfile:1.0-experimental
# Haskell base
FROM ubuntu:18.04 AS haskell-base

ARG USERID=1000
ARG GROUPID=1000
ARG USERNAME=haskell

# ref: https://github.com/commercialhaskell/lts-haskell/blob/master/lts-14.27.yaml
ARG GHC_VERSION=8.6.5
ARG CABAL_VERSION=2.4
ARG STACK_VERSION=2.1.3

ENV LANG="C.UTF-8" \
    LC_ALL="C.UTF-8" \
    GHC_RESOLVER_VERSION=lts-14.27 \
    STACK_ROOT=/home/${USERNAME}/.stack \
    PATH=/home/${USERNAME}/.local/bin:/home/${USERNAME}/.cabal/bin:/opt/cabal/${CABAL_VERSION}/bin:/opt/ghc/${GHC_VERSION}/bin:${STACK_ROOT}/programs/x86_64-linux/ghc-${GHC_VERSION}/bin:${PATH} \
    LD_LIBRARY_PATH=/usr/lib:${LD_LIBRARY_PATH} \
    DEBIAN_FRONTEND=noninteractive

## create user
RUN set -x && \
  groupadd -r -g ${GROUPID} ${USERNAME} && \
  useradd -m -g ${USERNAME} -u ${USERID} -d /home/${USERNAME} -s /bin/bash ${USERNAME}

## install stack
RUN set -x && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    curl \
    ca-certificates && \
  curl -sLO "https://github.com/commercialhaskell/stack/releases/download/v${STACK_VERSION}/stack-${STACK_VERSION}-linux-x86_64-static.tar.gz" && \
  if ! curl -sL "https://github.com/commercialhaskell/stack/releases/download/v${STACK_VERSION}/stack-${STACK_VERSION}-linux-x86_64-static.tar.gz.sha256" | sha256sum -c -; then \
    echo "stack-${STACK_VERSION} checksum was failed" >&2 && \
    exit 1 ;\
  fi ; \
  tar -xvzf stack-${STACK_VERSION}-linux-x86_64-static.tar.gz && \
  cp -L stack-${STACK_VERSION}-linux-x86_64-static/stack /usr/local/bin/stack && \
  apt-get purge --autoremove -y \
    ca-certificates \
    curl && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* stack-${STACK_VERSION}-linux-x86_64-static stack-${STACK_VERSION}-linux-x86_64-static.tar.gz

## install ghc
RUN set -x && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    software-properties-common && \
  add-apt-repository -y ppa:hvr/ghc && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    cabal-install-${CABAL_VERSION} \
    curl \
    ca-certificates \
    g++ \
    ghc-${GHC_VERSION} \
    git \
    libpq-dev \
    libtinfo-dev \
    make \
    netbase \
    openssh-client \
    xz-utils \
    zlib1g-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

USER ${USERNAME}

## config stack
RUN set -x && \
  mkdir -p /home/${USERNAME}/.local/bin ${STACK_ROOT}/global-project && \
  echo "packages: []" > ${STACK_ROOT}/global-project/stack.yaml && \
  stack config set system-ghc --global true && \
  stack config set install-ghc --global false && \
  stack config set resolver ${GHC_RESOLVER_VERSION} && \
  echo 'color: never\n' >> ${STACK_ROOT}/config.yaml

# add llvm
FROM haskell-base AS haskell-llvm-base

ARG LLVM_VERSION="6.0"
USER root

## install ghc
RUN set -x && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    clang-${LLVM_VERSION} \
    llvm-${LLVM_VERSION} \
    llvm-${LLVM_VERSION}-dev \
    libomp-dev \
    llvm-${LLVM_VERSION}-tools && \
  find /usr/bin -name "*${LLVM_VERSION}" | sed -e "s/-${LLVM_VERSION}//g" | xargs -I {} -n 1 bash -c "ln -s {}-${LLVM_VERSION} {}" && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  echo 'ghc-options:\n  "$everything": -O2 -fllvm\n' >> /home/haskell/.stack/config.yaml

USER haskell

# update the package index
FROM haskell-base AS stack-update

RUN set -x && \
  stack --no-terminal update

# update the package index
FROM haskell-llvm-base AS stack-llvm-update

RUN set -x && \
  stack --no-terminal update
