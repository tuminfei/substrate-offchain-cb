# Note: We don't use Alpine and its packaged Rust/Cargo because they're too often out of date,
# preventing them from being used to build RChain/Polkadot.
FROM phusion/baseimage:0.11 as builder
LABEL maintainer="wuminzhe@gmail.com"
LABEL description="This is the build stage for RChain. Here we create the binary."

WORKDIR /rchain

COPY . /rchain

# RUN echo "deb http://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse" > /etc/apt/sources.list && \
 # echo "deb http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse" >> /etc/apt/sources.list && \
 # echo "deb http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
 # echo "deb http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
 # echo "deb http://mirrors.aliyun.com/ubuntu/ xenial-proposed main restricted universe multiverse" >> /etc/apt/sources.list && \
 # echo "deb-src http://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse" >> /etc/apt/sources.list && \
 # echo "deb-src http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse" >> /etc/apt/sources.list && \
 # echo "deb-src http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
 # echo "deb-src http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
 # echo "deb-src http://mirrors.aliyun.com/ubuntu/ xenial-proposed main restricted universe multiverse" >> /etc/apt/sources.list

# ENV DEBIAN_FRONTEND noninteractive

# PREPARE OPERATING SYSTEM & BUILDING ENVIRONMENT
RUN apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y cmake pkg-config libssl-dev git clang libclang-dev 

RUN cd /rchain && rm -rf .git && git init

# UPDATE RUST DEPENDENCIES
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y && \
	export PATH="$PATH:$HOME/.cargo/bin" && \
  rustup update nightly && \
	RUSTUP_TOOLCHAIN=stable cargo install --git https://github.com/alexcrichton/wasm-gc && \
  # BUILD RUNTIME AND BINARY
	rustup target add wasm32-unknown-unknown --toolchain nightly && \
	RUSTUP_TOOLCHAIN=stable cargo build --release

# ===== SECOND STAGE ======

WORKDIR = /usr/local/bin

# RUN mv /usr/share/ca* /tmp && \
# 	rm -rf /usr/share/*  && \
# 	mv /tmp/ca-certificates /usr/share/ && \
# 	mkdir -p /root/.local/share/rchain && \
# 	ln -s /root/.local/share/rchain /data && \
# 	useradd -m -u 1000 -U -s /bin/sh -d /rchain rchain

COPY target/release/offchain-cb /usr/local/bin
COPY --from=builder /rchain/garlic_testnet.json /usr/local/bin

# checks
RUN ldd /usr/local/bin/offchain-cb && \
	/usr/local/bin/offchain-cb --version

# Shrinking
RUN rm -rf /usr/lib/python* && \
	rm -rf /usr/bin /usr/sbin /usr/share/man

# USER rchain
EXPOSE 30333 9933 9944
VOLUME ["/data"]

# ENTRYPOINT ["rchain"]
# CMD ["--chain=dev"]
