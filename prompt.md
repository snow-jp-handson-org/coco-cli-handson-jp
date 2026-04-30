# Cortex Code プロンプト集

## このファイルの使い方

各ステップのプロンプトを **Cortex Code CLI** にコピー＆ペーストして実行します。

**Cortex Code CLI のはじめかた**:
1. コマンドプロンプトまたはターミナルで `cortex` コマンドを実行
2. CLI 上のテキストボックスにプロンプトを貼り付けて Enter

---
## Step 0: データ準備

### 目的
本ハンズオン用サンプルデータの初期構築タスクの実行

### プロンプト

- 0-0. Snowflake CLI での SQL ファイル実行
```
snow sql -f setup.sql
```

## Step 1: データ探索

### 目的
各テーブル件数・サンプルデータ確認およびデータ整合性チェック

### プロンプト

- 1-1. 単一テーブルの概要把握
```
#SNOWRETAIL_DB.SNOWRETAIL_SCHEMA.EC_DATA このテーブルの概要を教えて
```

- 1-2. スキーマ内オブジェクト全体の概要把握
```
SNOWRETAIL_DB.SNOWRETAIL_SCHEMA この中のテーブルの概要を教えて
```

- 1-3. 簡易分析の実行
```
商品別売上上位5件を出して
```

- 1-4. 会話の文脈
```
ECのみで、月別に分けて見せて

ECの売上構成比を教えて
```

- 1-5. データ構造への示唆
```
SNOWRETAIL_DB.SNOWRETAIL_SCHEMA のデータ構造の問題点は何か、改善案を出して
```

---

## Step 2: Dynamic Table でデータ整備

### 目的
データ構造の問題点を解消するため、テーブルを結合・集計してデータマート用 Dynamic Table を作成する

### プロンプト
```
MART_SALESという名前でDynamic Tableを作成したい。また、作成にあたって商品名から類推してカテゴリ、ブランドのカラムも追加したい。
```

---

## Step 3: AGENTS.mdでプロジェクトルール定義

### 目的
AGENTS.mdの Before/After 比較でソフトガバナンスの効果を体感する。

### プロンプト

- 3-1. Before（AGENTS.mdなし）の動作確認
```
チャネル別、カテゴリ別のクロス集計を出して
```

- 3-2. AGENTS.mdの配置と内容確認
```
AGENTS.mdを読んで、どんなルールが定義されているか説明して
```

- 3-3. After（AGENTS.mdあり）の動作確認
```
チャネル別、カテゴリ別のクロス集計を出して
```

---

## Step 4: Subagent + Agent Teamsでバックグラウンド実行

### 目的
SubagentとAgent Teamsの違いを段階的に体験する。Phase 1→2→3 と進めることで「自分が指示する」から「Leadが統括する」への変化を実感する。

### プロンプト

- 4-1. 汎用Subagentのバックグラウンド起動
```
バックグラウンドで実行してください。
MART_SALESを使ってSemantic View（Step 6用）の設計案を調査してください。
どのディメンション・メジャーを定義すべきか提案してください。
```

- 4-2. Custom Agentの構造確認
```
.cortex/agents/data-quality-checker.md を読んで、
このCustom Agentがどんな専門性・制約を持っているか説明して
```

- 4-3. Custom AgentのBG起動
```
data-quality-checker を使って MART_SALES のデータ品質チェックをバックグラウンドで実行して
```

- 4-4. 2つのAgentを /agents で一元確認
```
/agents
```

- 4-5. Agent Teamsを起動
```
Agent Teamsを使って、MART_SALESの月次分析レポートを作成して。
以下を並列で行ってください：
・チャネル別・カテゴリ別の売上トレンド分析
・MART_SALESのデータ品質チェック
・分析結果をもとにした改善提案
```

- 4-6. Agent Teams進捗確認
```
/agents
```

---

## Step 5: Hooksでガバナンス（概要のみ）

### 目的
Hooksの仕組みを理解し、配布サンプルで活用イメージを掴む。

### プロンプト

- 5-1. hooks.jsonの構造説明とサンプル配布
```
hooks.jsonとブロックスクリプトを読んで、どんな制御をしているか説明して
```

---

## Step 6: Semantic View + Cortex AgentsでSI構築

### 目的
LOB（営業・マーケ等）がSnowflake Intelligence（SI）で自然言語分析できる環境を作る。

### プロンプト

- 6-1. Semantic Viewの作成
```
#MART_SALES #CUSTOMER_REVIEWS を使って、
SNOWRETAIL_DB.SNOWRETAIL_SCHEMA.SNOWRETAIL_SV という名前でSemantic Viewを作成してください。またyamlファイルはsemantic_viewというフォルダを作成し、その下snowretail_sv.yamlという名前で出力してください
```

- 6-2. cortex reflectで検証・デプロイ
```
@steps/part6/6-1_snowretail_sv.yaml をreflectして
```

- 6-3. Cortex Search Serviceの作成
```
#SNOW_RETAIL_DOCUMENTS を使って、Cortex Search Serviceを
SNOWRETAIL_DB.SNOWRETAIL_SCHEMA.HANDSON_DOCS_SEARCH という名前で作成して
```

- 6-4. Semantic View + Cortex SearchをAgentに統合
```
Semantic View（SNOWRETAIL_SV）とCortex Search（HANDSON_DOCS_SEARCH）を
両方使うCortex Agentを
SNOWRETAIL_DB.SNOWRETAIL_SCHEMA.SNOWRETAIL_HANDSON_AGENT という名前で作成して
```

- 6-5. Snowsight上でSI体験（質問例）
```
作成したCortex Agentを使って以下の結果を取得してください。


問い合わせ内容：「チャネル別の月次売上推移を教えてください」
```

---

## Step 7: Skillでレポート生成を標準化

### 目的
Skillの構造を理解し、カスタマイズして再実行する。チーム共有の効果を理解する。

### プロンプト

- 7-1. Skillの構造確認
```
monthly-sales-reportのSKILL.mdを読んで、このSkillが何をするものか、どんな手順で動くか説明して
```

- 7-2. Skillを実行
```
MART_SALESの最新データで月次売上分析レポートを作成して
```

- 7-3. Skillをカスタマイズ
```
このSkillのレポートに「EC/実店舗チャネル比較」のセクションを追加して。SKILL.mdを更新して
```

---

## Step 8: Streamlitでダッシュボード化

### 目的
ベースラインをCoCoで改修し、snow streamlit deployでSiSにデプロイする。

### プロンプト

- 8-1. ベースラインの確認
```
streamlit_app.py を読んで、現状何が表示されるか説明して
```

- 8-2. CoCoで改修
```
このStreamlitアプリに以下を追加して：
・チャネル（EC/RETAIL）でフィルタリングできるセレクトボックス
・カテゴリ別の月次売上推移グラフ（折れ線グラフ）
・売上Top10商品の横棒グラフ
```

- 8-3. Snowflakeへのデプロイ
```
では編集したstreamlit_app.pyを使用してstreamlitをデプロイしてください。
```

---

## Step 9: MCPでデータ全体像を可視化

### 目的
draw.io MCPを使って、ハンズオン全体のデータ全体像をER図として可視化する。

### プロンプト

- 9-1. drawio MCPの接続確認
```
/mcp
```

または ターミナルで:
```
cortex mcp list
```

```
draw.io MCPに接続する方法を教えて
```

- 9-2. ER図の作成
```
#EC_DATA #RETAIL_DATA #PRODUCT_MASTER #MART_SALES #CUSTOMER_REVIEWS #SNOW_RETAIL_DOCUMENTS
これらのテーブルの関係をdraw.ioでER図として可視化して
```

---

## Step 10: 振り返り + Profileでチームに展開

### 目的
今日作ったものをProfileで一括配布できることを理解する。

### プロンプト

- 10-1. セッションの振り返り
```
今日のセッションで何を作成・変更したかまとめて、profile.jsonとしてprofilesフォルダ下に出力して
```

- 10-2. Profile紹介
```
profile.jsonを読んで、何がパッケージされているか説明して
```

- 10-3. Profileの適用
```
cortex profile apply profile.json
```
