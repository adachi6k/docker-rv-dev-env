FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    autoconf automake autotools-dev curl python3 libmpc-dev \
    libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf \
    libtool patchutils bc zlib1g-dev libexpat-dev \
    git \
    device-tree-compiler \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ENV RISCV=/opt/riscv
WORKDIR $RISCV/tmp
RUN git clone --depth 1 https://github.com/riscv/riscv-gnu-toolchain.git \
 && cd riscv-gnu-toolchain \
 && ./configure --prefix=${RISCV} \
 && make -j$(nproc)

RUN git clone --depth 1 https://github.com/riscv/riscv-isa-sim.git \
 && cd riscv-isa-sim \
 && ./configure --prefix=${RISCV} \
 && make -j$(nproc) \
 && make install

ENV PATH=/opt/riscv/bin:${PATH}
ENV VERILATOR_ROOT=/opt/verilator

WORKDIR /opt
RUN git clone --depth 1 https://github.com/verilator/verilator.git \
 && cd verilator \
 && autoconf \
 && ./configure \
 && make -j$(nproc)