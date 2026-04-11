# docker-rv-dev-env

Docker image providing a RISC-V hardware development environment.

## Included Tools

| Tool | Version |
|------|---------|
| [riscv-gnu-toolchain](https://github.com/riscv/riscv-gnu-toolchain) | 2026.03.28 |
| [riscv-isa-sim (spike)](https://github.com/riscv/riscv-isa-sim) | 20260331-170f398 |
| [verilator](https://github.com/verilator/verilator) | v5.046 |
| [cmake](https://cmake.org/) | (from Ubuntu package) |
| [ninja (ninja-build)](https://ninja-build.org/) | (from Ubuntu package) |

## Bare-Metal Multilib Configuration

The toolchain is built for **RV32 bare-metal (newlib)** targets by default with the following configuration:

| Setting | Default |
|---------|---------|
| Default arch | `rv32im_zba_zbb_zbs` |
| Default ABI | `ilp32` |

### Supported multilib variants

| march | mabi |
|-------|------|
| `rv32i` | `ilp32` |
| `rv32im` | `ilp32` |
| `rv32imc` | `ilp32` |
| `rv32im_zba_zbb_zbs` | `ilp32` |
| `rv32imc_zba_zbb_zbs` | `ilp32` |

You can verify the multilib configuration inside the container.
Note that `riscv64-unknown-elf-gcc` is the standard toolchain name for both RV32 and RV64 bare-metal targets; multilib handles the architecture selection.

```sh
riscv64-unknown-elf-gcc --print-multi-lib
```

## Using the Pre-built Image

Images are published to GitHub Container Registry (GHCR) and updated automatically when tool versions change.

```sh
docker pull ghcr.io/adachi6k/docker-rv-dev-env:latest
docker run --rm -it ghcr.io/adachi6k/docker-rv-dev-env:latest bash
```

## CI Workflows

| Workflow | Trigger | Description |
|----------|---------|-------------|
| **Monthly upstream version check** | 1st of each month (UTC) / manual | Fetches the latest upstream releases for all three tools, compares them against the versions in `Dockerfile`, and opens a PR with the diff when a newer version is found. Does nothing if everything is already up to date. |
| **Build and push Docker image** | Push to `main` that changes `Dockerfile` / manual | Builds the Docker image and pushes it to GHCR with the `latest` tag, a date tag (`YYYYMMDD`), and a short-SHA tag. |

Both workflows can be triggered manually from the **Actions** tab via `workflow_dispatch`.

## Maintenance

Build settings are managed via build arguments (`ARG`) at the top of the `Dockerfile`.
To change a default, update the corresponding `ARG` value and rebuild the image.

| ARG | Default | Description |
|-----|---------|-------------|
| `UBUNTU_VERSION` | `24.04` | Ubuntu base image version |
| `RISCV_GNU_TOOLCHAIN_VERSION` | `2026.03.28` | riscv-gnu-toolchain git tag |
| `RISCV_ISA_SIM_VERSION` | `20260331-170f398` | riscv-isa-sim commit (YYYYMMDD-sha) |
| `VERILATOR_VERSION` | `v5.046` | Verilator git tag |
| `RISCV_TOOLCHAIN_ARCH` | `rv32im_zba_zbb_zbs` | Default `-march` for the bare-metal toolchain |
| `RISCV_TOOLCHAIN_ABI` | `ilp32` | Default `-mabi` for the bare-metal toolchain |
| `RISCV_MULTILIB_GENERATOR` | *(see below)* | Multilib generator string passed to `--with-multilib-generator` |

Default `RISCV_MULTILIB_GENERATOR` value:

```
rv32i-ilp32--;rv32im-ilp32--;rv32imc-ilp32--;rv32im_zba_zbb_zbs-ilp32--;rv32imc_zba_zbb_zbs-ilp32--
```

To override a build argument at build time:

```sh
docker build \
  --build-arg VERILATOR_VERSION=v5.026 \
  -t rv-dev-env .
```
