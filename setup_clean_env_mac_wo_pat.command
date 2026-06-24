#!/usr/bin/env bash
# =============================================================================
# setup_clean_env_mac.command  (macOS 用)
# -----------------------------------------------------------------------------
# zip 解凍した `coco-cli-handson-jp-main/` 直下に配置することを想定したスクリプト。
#
# 既存の ~/.snowflake/cortex/ や ~/.claude/ 等の個人 CoCo CLI 設定を一切汚さず、
# クリーンな環境でハンズオン用 cortex を起動する。
# Snowflake への接続情報は cortex の初期セットアップウィザードで手動設定する想定。
#
# === 起動方法 (3つから選べます) ===
#
# (推奨) Finder からダブルクリック
#   このファイル (setup_clean_env_mac.command) を Finder でダブルクリックすると、
#   Terminal.app が自動で開きスクリプトが実行されます。
#   ※ 初回は Gatekeeper の警告が出る場合があります。その時は
#     [Finder で右クリック → 開く] を選んでください。
#
# (代替1) ターミナルにドラッグ&ドロップ
#   ターミナルを起動してから本ファイルをターミナルウィンドウにドラッグして Enter。
#
# (代替2) cd してから実行
#   cd ~/Downloads/coco-cli-handson-jp-main
#   bash setup_clean_env_mac.command
#
# === 仕組み ===
#   - 解凍フォルダ自身 を SANDBOX_HOME (一時 HOME) として使う
#   - HOME / SNOWFLAKE_HOME を解凍フォルダに切り替える
#   - --setting-sources project で project スコープのみ有効化
#   - --no-mcp で個人 MCP 設定を無効化
#   - 終了後、解凍フォルダごと削除すれば既存環境に何も残らない
# =============================================================================

set -euo pipefail

# このスクリプト自身が置かれているディレクトリに自動で cd する。
# これにより Finder からダブルクリックされても正しいパスで動く。
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 解凍フォルダ自身を SANDBOX_HOME として使う
SANDBOX_HOME="$SCRIPT_DIR"

# プロジェクトルート確認 (.cortex があるか)
if [ ! -d "$SANDBOX_HOME/.cortex" ]; then
  echo "[ERROR] このスクリプトは coco-cli-handson-jp-main/ の直下に置いて実行してください。"
  echo "        現在の場所: $SANDBOX_HOME"
  echo ""
  echo "Press any key to close..."
  read -n 1 -s
  exit 1
fi

# cortex コマンドの存在確認
if ! command -v cortex >/dev/null 2>&1; then
  echo "[ERROR] cortex コマンドが見つかりません。"
  echo "        CoCo CLI をインストールして PATH を通してから再度実行してください。"
  echo ""
  echo "Press any key to close..."
  read -n 1 -s
  exit 1
fi

cat <<INFO

============================================================
 クリーン環境で cortex を起動します (macOS)
============================================================
  作業ディレクトリ / 一時 HOME : $SANDBOX_HOME

  既存の ~/.snowflake/cortex や ~/.claude には触れません。
  接続情報は初回起動時のセットアップウィザードで設定してください
  (情報は $SANDBOX_HOME/.snowflake/ 配下に保存されます)。

  終了するには /exit と入力してください。
  ハンズオン後、不要であれば解凍フォルダごと削除すれば
  すべての設定・履歴も一緒に消去されます。
============================================================

INFO

# 環境変数を一時的に上書きして cortex を起動
HOME="$SANDBOX_HOME" \
SNOWFLAKE_HOME="$SANDBOX_HOME/.snowflake" \
exec cortex \
  -w "$SANDBOX_HOME" \
  --setting-sources project \
  --no-mcp \
  --no-auto-update \
  -m "claude-sonnet-4-6"
