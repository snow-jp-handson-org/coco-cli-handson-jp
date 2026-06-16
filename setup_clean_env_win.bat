﻿@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM =============================================================================
REM setup_clean_env_win.bat  (Windows 用 — PAT 自動生成 & cortex 起動)
REM -----------------------------------------------------------------------------
REM Snowflake CLI (snow) を使って PAT を自動生成し、クリーン環境で cortex を起動する。
REM 既存の %USERPROFILE%\.snowflake\ 配下のファイルには一切触れない。
REM
REM === 前提条件 ===
REM   - Snowflake CLI (snow) がインストール済み
REM   - CoCo CLI (cortex) がインストール済み
REM
REM === 起動方法 ===
REM   エクスプローラーからダブルクリック / コマンドプロンプトで実行
REM =============================================================================

cd /d "%~dp0"
set "SANDBOX_HOME=%~dp0"
if "%SANDBOX_HOME:~-1%"=="\" set "SANDBOX_HOME=%SANDBOX_HOME:~0,-1%"

set "PAT_NAME=CORTEX_HANDSON_PAT"
set "CONFIG_FILE=%SANDBOX_HOME%\.snowflake\config.toml"

REM --- 前提チェック ---
if not exist "%SANDBOX_HOME%\.cortex" (
    echo [ERROR] このバッチは coco-cli-handson-jp-main の直下に置いて実行してください。
    echo         current location: %SANDBOX_HOME%
    echo.
    pause
    exit /b 1
)

where cortex >nul 2>nul
if errorlevel 1 (
    echo [ERROR] cortex コマンドが見つかりません。
    echo         CoCo CLI をインストールして PATH を通してから再度実行してください。
    echo.
    pause
    exit /b 1
)

where snow >nul 2>nul
if errorlevel 1 (
    echo [ERROR] snow コマンド (Snowflake CLI) が見つかりません。
    echo         https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation からインストールしてください。
    echo.
    pause
    exit /b 1
)

REM =============================================================================
REM メインフロー
REM =============================================================================
echo.
echo ============================================================
echo  CoCo CLI 自動セットアップ (Windows)
echo ============================================================
echo.

if exist "%CONFIG_FILE%" (
    echo 既存の接続設定が見つかりました。接続テストを実行します...
    echo.

    set "SNOWFLAKE_HOME=%SANDBOX_HOME%\.snowflake"
    snow connection test -c handson >nul 2>nul
    if !errorlevel! equ 0 (
        echo --- 接続 OK。cortex を起動します ---
        echo.
        goto :launch_cortex
    ) else (
        echo 接続テストに失敗しました。PAT を再生成します。
        echo.
        goto :ask_credentials
    )
) else (
    echo Snowflake の接続情報を入力してください。
    echo PAT (Programmatic Access Token) を自動生成し、cortex を起動します。
    echo.
    goto :ask_credentials
)

:ask_credentials
set /p "SF_ACCOUNT=アカウント識別子 (例: ORGNAME-ACCOUNTNAME): "
set /p "SF_USER=ユーザ名: "

REM パスワード入力 (非表示)
set "SF_PASSWORD="
echo|set /p="パスワード: "
powershell -Command "$p = Read-Host -AsSecureString; $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($p); [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)" > "%TEMP%\pw_tmp.txt"
set /p SF_PASSWORD=<"%TEMP%\pw_tmp.txt"
del "%TEMP%\pw_tmp.txt" >nul 2>nul
echo.

if "%SF_ACCOUNT%"=="" goto :input_error
if "%SF_USER%"=="" goto :input_error
if "%SF_PASSWORD%"=="" goto :input_error

call :generate_pat
if errorlevel 1 (
    pause
    exit /b 1
)

echo --- 接続テスト中... ---
set "SNOWFLAKE_HOME=%SANDBOX_HOME%\.snowflake"
snow connection test -c handson
if errorlevel 1 (
    echo [ERROR] 接続テストに失敗しました。
    echo   PAT の Network Policy bypass は 24 時間有効です。
    echo   時間切れの場合はスクリプトを再実行してください。
    pause
    exit /b 1
)
echo.
echo --- セットアップ完了。cortex を起動します ---
echo.
goto :launch_cortex

:input_error
echo [ERROR] すべての項目を入力してください。
pause
exit /b 1

REM =============================================================================
REM PAT 生成関数
REM =============================================================================
:generate_pat
echo --- PAT を生成しています... ---

set "SNOWFLAKE_PASSWORD=%SF_PASSWORD%"
snow sql --temporary-connection --account "%SF_ACCOUNT%" --user "%SF_USER%" -q "ALTER USER IF EXISTS %SF_USER% REMOVE PAT %PAT_NAME%" >nul 2>nul

snow sql --temporary-connection --account "%SF_ACCOUNT%" --user "%SF_USER%" -q "ALTER USER ADD PAT %PAT_NAME% DAYS_TO_EXPIRY = 30 MINS_TO_BYPASS_NETWORK_POLICY_REQUIREMENT = 1440 COMMENT = 'CoCo CLI handson auto-generated token'" --format json > "%TEMP%\pat_result.txt" 2>&1
if errorlevel 1 (
    echo [ERROR] PAT の生成に失敗しました:
    type "%TEMP%\pat_result.txt"
    echo.
    echo 考えられる原因:
    echo   - パスワードが間違っている
    echo   - PAT の上限 (15個) に達している
    echo   - アカウント識別子が間違っている
    del "%TEMP%\pat_result.txt" >nul 2>nul
    set "SNOWFLAKE_PASSWORD="
    exit /b 1
)

REM トークン抽出
for /f "usebackq delims=" %%A in ("%TEMP%\pat_result.txt") do set "PAT_RAW=%%A"
del "%TEMP%\pat_result.txt" >nul 2>nul

REM PowerShell でJSONからトークン抽出
for /f "usebackq delims=" %%T in (`powershell -Command "$raw = Get-Content '%TEMP%\pat_result.txt' -Raw 2>$null; if(-not $raw){$raw='%PAT_RAW%'}; ($raw | ConvertFrom-Json).token_secret 2>$null; if(-not $?){[regex]::Match($raw, '\"token_secret\"\s*:\s*\"([^\"]+)\"').Groups[1].Value}"`) do set "TOKEN_SECRET=%%T"

if "%TOKEN_SECRET%"=="" (
    REM フォールバック: PowerShell で直接パース
    for /f "usebackq delims=" %%T in (`powershell -Command "[regex]::Match('%PAT_RAW%', 'token_secret.{3,5}([A-Za-z0-9_\-\.]+)').Groups[1].Value"`) do set "TOKEN_SECRET=%%T"
)

if "%TOKEN_SECRET%"=="" (
    echo [ERROR] トークンの抽出に失敗しました。
    echo PAT_RAW: %PAT_RAW%
    set "SNOWFLAKE_PASSWORD="
    exit /b 1
)

if not exist "%SANDBOX_HOME%\.snowflake" mkdir "%SANDBOX_HOME%\.snowflake"

(
echo default_connection_name = "handson"
echo.
echo [connections.handson]
echo account = "%SF_ACCOUNT%"
echo user = "%SF_USER%"
echo password = "%TOKEN_SECRET%"
echo warehouse = "COMPUTE_WH"
) > "%CONFIG_FILE%"

set "SNOWFLAKE_PASSWORD="
echo --- PAT 生成完了。接続設定を作成しました ---
exit /b 0

REM =============================================================================
REM cortex 起動
REM =============================================================================
:launch_cortex
set "USERPROFILE=%SANDBOX_HOME%"
set "HOME=%SANDBOX_HOME%"
set "SNOWFLAKE_HOME=%SANDBOX_HOME%\.snowflake"

cortex ^
  -c handson ^
  -w "%SANDBOX_HOME%" ^
  --setting-sources project ^
  --no-mcp ^
  --no-auto-update ^
  -m "claude-sonnet-4-6"

echo.
echo cortex セッションを終了しました。
pause

endlocal
