@echo off
setlocal

REM =============================================================================
REM setup_clean_env_win.bat  (Windows 用)
REM -----------------------------------------------------------------------------
REM zip 解凍した `coco-cli-handson-jp-main\` 直下に配置することを想定したバッチ。
REM
REM 既存の %USERPROFILE%\.snowflake\cortex\ や %USERPROFILE%\.claude\ 等の
REM 個人 CoCo CLI 設定を一切汚さず、クリーンな環境でハンズオン用 cortex を起動する。
REM Snowflake 接続情報は cortex の初期セットアップウィザードで手動設定する想定。
REM
REM === 起動方法 (3つから選べます) ===
REM
REM  (推奨) エクスプローラーからダブルクリック
REM    本ファイル (setup_clean_env_win.bat) をダブルクリックすると
REM    コマンドプロンプトが自動で開きスクリプトが実行されます。
REM
REM  (代替1) コマンドプロンプトにドラッグ&ドロップ
REM    cmd を起動してから本ファイルをウィンドウにドラッグして Enter。
REM
REM  (代替2) cd してから実行
REM    cd C:\Users\<user>\Downloads\coco-cli-handson-jp-main
REM    setup_clean_env_win.bat
REM
REM === 仕組み ===
REM   - 解凍フォルダ自身 (このバッチが置かれた場所) を SANDBOX_HOME として使う
REM       * .cortex\                   project スコープ設定としてそのまま読まれる
REM       * .snowflake\                cortex 起動時に自動作成される
REM   - USERPROFILE / HOME / SNOWFLAKE_HOME を解凍フォルダに切り替える
REM       (setlocal 配下なのでバッチ終了後に自動で元に戻る)
REM   - --setting-sources project で project スコープのみ有効化
REM   - --no-mcp で個人 MCP 設定を無効化
REM   - 終了後、解凍フォルダごと削除すれば既存環境に何も残らない
REM =============================================================================

REM このバッチが置かれているディレクトリへ移動 (末尾の \ を除いて SANDBOX_HOME を作る)
cd /d "%~dp0"
set "SANDBOX_HOME=%~dp0"
if "%SANDBOX_HOME:~-1%"=="\" set "SANDBOX_HOME=%SANDBOX_HOME:~0,-1%"

REM プロジェクトルート確認 (.cortex があるか)
if not exist "%SANDBOX_HOME%\.cortex" (
    echo [ERROR] このバッチは coco-cli-handson-jp-main\ の直下に置いて実行してください。
    echo         現在の場所: %SANDBOX_HOME%
    echo.
    pause
    exit /b 1
)

REM cortex コマンドの存在確認
where cortex >nul 2>nul
if errorlevel 1 (
    echo [ERROR] cortex コマンドが見つかりません。
    echo         CoCo CLI をインストールして PATH を通してから再度実行してください。
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  クリーン環境で cortex を起動します ^(Windows^)
echo ============================================================
echo   作業ディレクトリ / 一時 HOME : %SANDBOX_HOME%
echo.
echo   既存の %%USERPROFILE%%\.snowflake\cortex や .claude には触れません。
echo   接続情報は初回起動時のセットアップウィザードで設定してください
echo   ^(情報は %SANDBOX_HOME%\.snowflake\ 配下に保存されます^)。
echo.
echo   終了するには /exit と入力してください。
echo   ハンズオン後、不要であれば解凍フォルダごと削除すれば
echo   すべての設定・履歴も一緒に消去されます。
echo ============================================================
echo.

REM 環境変数を一時的に上書きして cortex を起動
REM setlocal 配下なのでバッチ終了時に自動で元に戻る
set "USERPROFILE=%SANDBOX_HOME%"
set "HOME=%SANDBOX_HOME%"
set "SNOWFLAKE_HOME=%SANDBOX_HOME%\.snowflake"

cortex ^
  -w "%SANDBOX_HOME%" ^
  --setting-sources project ^
  --no-mcp ^
  --no-auto-update ^
  -m "claude-sonnet-4-6"

REM cortex 終了後にウィンドウを閉じないよう pause
echo.
echo cortex セッションを終了しました。
pause

endlocal
