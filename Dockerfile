ARG UBUNTU_VERSION=24.04
ARG RISCV_GNU_TOOLCHAIN_VERSION=2026.03.28
ARG RISCV_ISA_SIM_VERSION=20260324-204b88d
ARG VERILATOR_VERSION=v5.046

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
    perl groff \
    help2man \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ENV RISCV=/opt/riscv
WORKDIR /tmp/build

RUN git clone --depth 1 --branch ${RISCV_GNU_TOOLCHAIN_VERSION} \
    https://github.com/riscv/riscv-gnu-toolchain.git \
 && cd riscv-gnu-toolchain \
 && ./configure --prefix=${RISCV} \
 && make -j$(nproc)

RUN COMMIT_SHA=$(echo ${RISCV_ISA_SIM_VERSION} | cut -d- -f2) \
 && git clone --filter=blob:none --no-checkout --branch master --single-branch --no-tags \
    https://github.com/riscv/riscv-isa-sim.git riscv-isa-sim \
 && cd riscv-isa-sim \
 && git checkout ${COMMIT_SHA} \
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
    cmake \
    ninja-build \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ENV RISCV=/opt/riscv
ENV VERILATOR_ROOT=/opt/verilator
ENV PATH=/opt/riscv/bin:/opt/verilator/bin:${PATH}

COPY --from=builder ${RISCV} ${RISCV}
COPY --from=builder ${VERILATOR_ROOT} ${VERILATOR_ROOT}