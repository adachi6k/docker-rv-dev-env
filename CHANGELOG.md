# Changelog

## [Unreleased]

### Container Usage Issue Fixes (コンテナ活用時の問題点への対応)

以下の問題点が特定され、対応を実施した。

#### 問題 1: `VERILATOR_ROOT` パスの不一致

- **原因**: ビルドステージでは `VERILATOR_ROOT=/opt/verilator` を使用していたが、
  実際の include ファイルは `/opt/verilator/share/verilator/include/` に配置される。
- **対応**: ランタイムステージの `VERILATOR_ROOT` 環境変数を
  `/opt/verilator/share/verilator` に設定するよう修正済み。

#### 問題 2: CMake の Verilator パッケージによる `VERILATOR_ROOT` の再注入

- **原因**: `find_package(verilator)` が内部でインストールプレフィックス
  (`/opt/verilator`) を `VERILATOR_ROOT` として再設定し、
  `${VERILATOR_ROOT}/include/` に include ファイルを期待する。
  環境変数の変更だけでは回避できなかった。
- **対応**: Dockerfile ランタイムステージに互換 symlink を追加。
  `/opt/verilator/include` → `/opt/verilator/share/verilator/include`
  これにより、CMake が `/opt/verilator/include/` を参照した場合でも
  正しい include ファイルが見つかる。

#### 問題 3: `zlib.h` が存在しない (FST トレース用 C++ ビルドの失敗)

- **原因**: ランタイムイメージに `zlib1g-dev` が含まれておらず、
  FST トレース機能を使う C++ ビルドで `zlib.h` not found エラーが発生。
- **対応**: ランタイムステージの apt インストールに `zlib1g-dev` を追加済み。

#### 問題 4: `cmake --build . --target all` に含まれる補助 XML ターゲットの失敗

- **原因**: `all` ターゲットに含まれる補助 xml ターゲットが同じ Verilator 環境変数
  問題で失敗していた。シミュレーション実行ファイル自体は別ターゲット。
- **対応**: 上記 symlink 対応（問題 2）により、all ターゲット内の補助ターゲットも
  含めて Verilator include パスが解決されるようになる。
  ctest 実行前に必要なシミュレータターゲットを明示的にビルドすること。

### 変更ファイル

- `Dockerfile`: ランタイムステージに Verilator include 互換 symlink を追加
  (`/opt/verilator/include → /opt/verilator/share/verilator/include`)
