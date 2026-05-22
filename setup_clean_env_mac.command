#!/usr/bin/env bash
# =============================================================================
# setup_auto_mac.command  (macOS 用 — PAT 自動生成 & cortex 起動)
# -----------------------------------------------------------------------------
# Snowflake CLI (snow) を使って PAT を自動生成し、クリーン環境で cortex を起動する。
# 既存の ~/.snowflake/ 配下のファイルには一切触れない。
#
# === 前提条件 ===
#   - Snowflake CLI (snow) がインストール済み
#   - Cortex Code CLI (cortex) がインストール済み
#
# === 起動方法 ===
#   Finder からダブルクリック / ターミナルで bash setup_auto_mac.command
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SANDBOX_HOME="$SCRIPT_DIR"
PAT_NAME="CORTEX_HANDSON_PAT"
CONFIG_FILE="$SANDBOX_HOME/.snowflake/config.toml"

# --- 前提チェック ---
if [ ! -d "$SANDBOX_HOME/.cortex" ]; then
  echo "[ERROR] このスクリプトは coco-cli-handson-jp-main/ の直下に置いて実行してください。"
  echo "        現在の場所: $SANDBOX_HOME"
  read -n 1 -s
  exit 1
fi

if ! command -v cortex >/dev/null 2>&1; then
  echo "[ERROR] cortex コマンドが見つかりません。"
  echo "        CoCo CLI をインストールして PATH を通してから再度実行してください。"
  read -n 1 -s
  exit 1
fi

if ! command -v snow >/dev/null 2>&1; then
  echo "[ERROR] snow コマンド (Snowflake CLI) が見つかりません。"
  echo "        https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation からインストールしてください。"
  read -n 1 -s
  exit 1
fi

# =============================================================================
# PAT 生成関数
# =============================================================================
generate_pat() {
  local sf_account="$1"
  local sf_user="$2"
  local sf_password="$3"

  echo "--- PAT を生成しています... ---"

  SNOWFLAKE_PASSWORD="$sf_password" snow sql \
    --temporary-connection \
    --account "$sf_account" \
    --user "$sf_user" \
    -q "ALTER USER IF EXISTS $sf_user REMOVE PAT $PAT_NAME" \
    2>/dev/null || true

  local pat_result
  pat_result=$(SNOWFLAKE_PASSWORD="$sf_password" snow sql \
    --temporary-connection \
    --account "$sf_account" \
    --user "$sf_user" \
    -q "ALTER USER ADD PAT $PAT_NAME DAYS_TO_EXPIRY = 30 MINS_TO_BYPASS_NETWORK_POLICY_REQUIREMENT = 1440 COMMENT = 'CoCo CLI handson auto-generated token'" \
    --format json 2>&1) || {
    echo "[ERROR] PAT の生成に失敗しました:"
    echo "$pat_result"
    echo ""
    echo "考えられる原因:"
    echo "  - パスワードが間違っている"
    echo "  - PAT の上限 (15個) に達している"
    echo "  - アカウント識別子が間違っている"
    read -n 1 -s
    exit 1
  }

  local token_secret
  token_secret=$(echo "$pat_result" | tr -d '\n\r ' | grep -o '"token_secret":"[^"]*"' | head -1 | cut -d'"' -f4)

  if [ -z "$token_secret" ]; then
    echo "[ERROR] トークンの抽出に失敗しました。snow sql の出力:"
    echo "$pat_result"
    read -n 1 -s
    exit 1
  fi

  mkdir -p "$SANDBOX_HOME/.snowflake"

  printf 'default_connection_name = "handson"\n\n[connections.handson]\naccount = "%s"\nuser = "%s"\npassword = "%s"\nwarehouse = "COMPUTE_WH"\n' \
    "$sf_account" "$sf_user" "$token_secret" \
    > "$CONFIG_FILE"
  chmod 600 "$CONFIG_FILE"

  echo "--- PAT 生成完了。接続設定を作成しました ---"
}

# =============================================================================
# メインフロー
# =============================================================================
cat <<BANNER

============================================================
 Cortex Code CLI 自動セットアップ (macOS)
============================================================

BANNER

if [ -f "$CONFIG_FILE" ]; then
  echo "既存の接続設定が見つかりました。接続テストを実行します..."
  echo ""

  if SNOWFLAKE_HOME="$SANDBOX_HOME/.snowflake" snow connection test -c handson 2>/dev/null; then
    echo ""
    echo "--- 接続 OK。cortex を起動します ---"
    echo ""
  else
    echo ""
    echo "接続テストに失敗しました。PAT を再生成します。"
    echo ""

    read -rp "アカウント識別子 (例: ORGNAME-ACCOUNTNAME): " SF_ACCOUNT
    read -rp "ユーザ名: " SF_USER
    read -rsp "パスワード: " SF_PASSWORD
    echo ""

    if [ -z "$SF_ACCOUNT" ] || [ -z "$SF_USER" ] || [ -z "$SF_PASSWORD" ]; then
      echo "[ERROR] すべての項目を入力してください。"
      read -n 1 -s
      exit 1
    fi

    generate_pat "$SF_ACCOUNT" "$SF_USER" "$SF_PASSWORD"

    echo "--- 接続テスト中... ---"
    if ! SNOWFLAKE_HOME="$SANDBOX_HOME/.snowflake" snow connection test -c handson; then
      echo "[ERROR] 接続テストに失敗しました。"
      read -n 1 -s
      exit 1
    fi
    echo ""
    echo "--- セットアップ完了。cortex を起動します ---"
    echo ""
  fi
else
  echo "Snowflake の接続情報を入力してください。"
  echo "PAT (Programmatic Access Token) を自動生成し、cortex を起動します。"
  echo ""

  read -rp "アカウント識別子 (例: ORGNAME-ACCOUNTNAME): " SF_ACCOUNT
  read -rp "ユーザ名: " SF_USER
  read -rsp "パスワード: " SF_PASSWORD
  echo ""

  if [ -z "$SF_ACCOUNT" ] || [ -z "$SF_USER" ] || [ -z "$SF_PASSWORD" ]; then
    echo "[ERROR] すべての項目を入力してください。"
    read -n 1 -s
    exit 1
  fi

  generate_pat "$SF_ACCOUNT" "$SF_USER" "$SF_PASSWORD"

  echo "--- 接続テスト中... ---"
  if ! SNOWFLAKE_HOME="$SANDBOX_HOME/.snowflake" snow connection test -c handson; then
    echo "[ERROR] 接続テストに失敗しました。"
    echo "  PAT の Network Policy bypass は 24 時間有効です。"
    echo "  時間切れの場合はスクリプトを再実行してください。"
    read -n 1 -s
    exit 1
  fi
  echo ""
  echo "--- セットアップ完了。cortex を起動します ---"
  echo ""
fi

# --- cortex 起動 ---
HOME="$SANDBOX_HOME" \
SNOWFLAKE_HOME="$SANDBOX_HOME/.snowflake" \
exec cortex \
  -c handson \
  -w "$SANDBOX_HOME" \
  --setting-sources project \
  --no-mcp \
  --no-auto-update \
  -m "claude-sonnet-4-6"
