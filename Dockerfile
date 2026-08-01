ARG UBUNTU_VERSION=24.04
ARG RISCV_GNU_TOOLCHAIN_VERSION=2026.07.15
ARG RISCV_ISA_SIM_VERSION=20260728-3d8eb08
ARG VERILATOR_VERSION=v5.050
ARG RISCV_TOOLCHAIN_ARCH=rv32im_zba_zbb_zbs
ARG RISCV_TOOLCHAIN_ABI=ilp32
ARG RISCV_MULTILIB_GENERATOR="rv32i-ilp32--;rv32im-ilp32--;rv32imc-ilp32--;rv32im_zba_zbb_zbs-ilp32--;rv32imc_zba_zbb_zbs-ilp32--"
ARG RISCV_TEST_ENV_VERSION=20260109-a1c373e
ARG RISCV_TESTS_VERSION=20260424-0bbecd1

# ---- Build Stage ----
FROM ubuntu:${UBUNTU_VERSION} AS builder
ARG RISCV_GNU_TOOLCHAIN_VERSION
ARG RISCV_ISA_SIM_VERSION
ARG VERILATOR_VERSION
ARG RISCV_TOOLCHAIN_ARCH
ARG RISCV_TOOLCHAIN_ABI
ARG RISCV_MULTILIB_GENERATOR
ARG RISCV_TEST_ENV_VERSION
ARG RISCV_TESTS_VERSION
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    autoconf automake autotools-dev curl python3 libmpc-dev \
    libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf \
    libtool patchutils bc zlib1g-dev libexpat-dev \
    ccache \
    mold \
    libgoogle-perftools-dev libjemalloc-dev numactl perl-doc \
    libfl2 libfl-dev \
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
    --with-arch=${RISCV_TOOLCHAIN_ARCH} \
    --with-abi=${RISCV_TOOLCHAIN_ABI} \
    --with-multilib-generator="${RISCV_MULTILIB_GENERATOR}" \
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

RUN RISCV_TEST_ENV_SHA=$(echo ${RISCV_TEST_ENV_VERSION} | cut -d- -f2) \
 && git clone --filter=blob:none --no-checkout --branch master --single-branch --no-tags \
    https://github.com/riscv/riscv-test-env.git riscv-test-env \
 && cd riscv-test-env \
 && git checkout ${RISCV_TEST_ENV_SHA} \
 && cd .. \
 && mkdir -p /opt/riscv-test-env/p \
 && cp riscv-test-env/encoding.h /opt/riscv-test-env/ \
 && cp riscv-test-env/p/riscv_test.h /opt/riscv-test-env/p/ \
 && cp riscv-test-env/p/link.ld /opt/riscv-test-env/p/ \
 && RISCV_TESTS_SHA=$(echo ${RISCV_TESTS_VERSION} | cut -d- -f2) \
 && git clone --filter=blob:none --no-checkout --single-branch --no-tags \
    https://github.com/riscv-software-src/riscv-tests.git riscv-tests \
 && cd riscv-tests \
 && git sparse-checkout set isa/macros/scalar \
 && git checkout ${RISCV_TESTS_SHA} \
 && cd .. \
 && cp riscv-tests/isa/macros/scalar/test_macros.h /opt/riscv-test-env/p/

# ---- Runtime Stage ----
FROM ubuntu:${UBUNTU_VERSION}
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    libmpc3 \
    libmpfr6 \
    libgmp10 \
    python3 \
    ccache \
    mold \
    z3 \
    zlib1g \
    zlib1g-dev \
    libgoogle-perftools4 \
    libjemalloc-dev \
    numactl \
    libfl2 \
    libexpat1 \
    device-tree-compiler \
    build-essential \
    perl \
    cmake \
    ninja-build \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ENV RISCV=/opt/riscv
ENV VERILATOR_ROOT=/opt/verilator/share/verilator
ENV PATH=/opt/riscv/bin:/opt/verilator/bin:${PATH}

COPY --from=builder ${RISCV} ${RISCV}
COPY --from=builder /opt/verilator /opt/verilator
COPY --from=builder /opt/riscv-test-env /opt/riscv-test-env

# CMake's find_package(verilator) re-injects VERILATOR_ROOT as the install
# prefix (/opt/verilator), then looks for headers at ${VERILATOR_ROOT}/include.
# Create a compatibility symlink so both paths resolve correctly.
RUN ln -sf /opt/verilator/share/verilator/include /opt/verilator/include
