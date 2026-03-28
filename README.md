# docker-rv-dev-env

Docker image providing a RISC-V hardware development environment.

## Included Tools

| Tool | Version |
|------|---------|
| [riscv-gnu-toolchain](https://github.com/riscv/riscv-gnu-toolchain) | 2024.04.12 |
| [riscv-isa-sim (spike)](https://github.com/riscv/riscv-isa-sim) | v1.1.0 |
| [verilator](https://github.com/verilator/verilator) | v5.024 |

## Maintenance

Tool versions are managed via build arguments (`ARG`) at the top of the `Dockerfile`.
To update a tool version, change the corresponding `ARG` default value and rebuild the image.

| ARG | Default | Description |
|-----|---------|-------------|
| `UBUNTU_VERSION` | `22.04` | Ubuntu base image version |
| `RISCV_GNU_TOOLCHAIN_VERSION` | `2024.04.12` | riscv-gnu-toolchain git tag |
| `RISCV_ISA_SIM_VERSION` | `v1.1.0` | riscv-isa-sim git tag |
| `VERILATOR_VERSION` | `v5.024` | Verilator git tag |

To override a version at build time:

```sh
docker build \
  --build-arg VERILATOR_VERSION=v5.026 \
  -t rv-dev-env .
```
