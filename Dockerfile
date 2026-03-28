ARG UBUNTU_VERSION=22.04
ARG RISCV_GNU_TOOLCHAIN_VERSION=2024.04.12
ARG RISCV_ISA_SIM_VERSION=v1.1.0
ARG VERILATOR_VERSION=v5.024

# ---- Build Stage ----
FROM ubuntu:${UBUNTU_VERSION} AS builder
ARG RISCV_GNU_TOOLCHAIN_VERSION
ARG RISCV_ISA_SIM_VERSION
ARG VERILATOR_VERSION
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
WORKDIR /tmp/build

RUN git clone --depth 1 --branch ${RISCV_GNU_TOOLCHAIN_VERSION} \
    https://github.com/riscv/riscv-gnu-toolchain.git \
 && cd riscv-gnu-toolchain \
 && ./configure --prefix=${RISCV} \
 && make -j$(nproc)

RUN git clone --depth 1 --branch ${RISCV_ISA_SIM_VERSION} \
    https://github.com/riscv/riscv-isa-sim.git \
 && cd riscv-isa-sim \
 && ./configure --prefix=${RISCV} \
 && make -j$(nproc) \
 && make install

ENV VERILATOR_ROOT=/opt/verilator
RUN git clone --depth 1 --branch ${VERILATOR_VERSION} \
    https://github.com/verilator/verilator.git \
 && cd verilator \
 && autoconf \
 && ./configure --prefix=${VERILATOR_ROOT} \
 && make -j$(nproc) \
 && make install

# ---- Runtime Stage ----
FROM ubuntu:${UBUNTU_VERSION}
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    libmpc3 \
    libmpfr6 \
    libgmp10 \
    python3 \
    zlib1g \
    libexpat1 \
    device-tree-compiler \
    build-essential \
    perl \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ENV RISCV=/opt/riscv
ENV VERILATOR_ROOT=/opt/verilator
ENV PATH=/opt/riscv/bin:/opt/verilator/bin:${PATH}

COPY --from=builder ${RISCV} ${RISCV}
COPY --from=builder ${VERILATOR_ROOT} ${VERILATOR_ROOT}