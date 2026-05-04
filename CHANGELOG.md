# Changelog

## [2026-05-04]

### Fixed: Container usage issues

- **CMake `find_package(verilator)` re-injects install prefix** — Added compatibility symlink
  `/opt/verilator/include → /opt/verilator/share/verilator/include` so CMake resolves headers
  correctly regardless of which path it uses.
