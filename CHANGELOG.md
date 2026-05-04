# Changelog

## [Unreleased]

### Fixed: Container usage issues

- **`VERILATOR_ROOT` path mismatch** — Set `VERILATOR_ROOT=/opt/verilator/share/verilator` in
  the runtime stage to match the actual include location.
- **CMake `find_package(verilator)` re-injects install prefix** — Added compatibility symlink
  `/opt/verilator/include → /opt/verilator/share/verilator/include` so CMake resolves headers
  correctly regardless of which path it uses.
- **Missing `zlib.h` (FST trace C++ build failure)** — Added `zlib1g-dev` to the runtime apt
  install.
- **Auxiliary XML targets failing in `cmake --build . --target all`** — Resolved by the symlink
  fix above; build simulator targets explicitly before running `ctest`.
