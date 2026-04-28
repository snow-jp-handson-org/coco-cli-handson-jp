# Step 9: draw.io MCP でデータ全体像を可視化

## 概要

このガイドでは、draw.io MCP を Cortex Code CLI（CoCo）に接続し、ハンズオン全体のデータ構造をER図として可視化する手順を説明します。

**所要時間**: 20分  
**使用機能**: `cortex mcp add`、draw.io MCP（App Server）、ER図生成  
**参照**: [jgraph/drawio-mcp](https://github.com/jgraph/drawio-mcp)（公式）

---

## draw.io MCP の2種類について

| | drawio-app（推奨） | drawio |
|---|---|---|
| 接続 | URL のみ（インストール不要） | Node.js / npm が必要 |
| 表示 | **CoCo のチャット内にインライン表示** | ブラウザで draw.io エディタが開く |
| WOW感 | 高（会話内に図が出現） | 低（タブ切り替え発生） |

→ ハンズオンでは **drawio-app（インライン表示）を推奨**

---

## 9-1: draw.io MCPの接続

### Step 1: 現在の MCP 一覧を確認

```bash
cortex mcp list
```

### Step 2: draw.io MCP（App Server）を追加する

Node.js 不要、URL を指定するだけで追加できます：

```bash
cortex mcp add drawio-app --sse https://mcp.draw.io/mcp
```

### Step 3: 接続を確認

```bash
cortex mcp list
```

`drawio-app` が表示されれば接続完了です。

### CoCo に確認させる場合

```
draw.io MCPに接続する方法を教えて
```

---

## 9-2: ER図の作成

draw.io MCP が接続できたら、CoCoのプロンプトに以下を入力します：

```
#EC_DATA #RETAIL_DATA #PRODUCT_MASTER #MART_SALES #CUSTOMER_REVIEWS #SNOW_RETAIL_DOCUMENTS
これらのテーブルの関係をdraw.ioでER図として可視化して
```

**`drawio-app` の場合、ER図がそのままチャット内に表示されます。**

---

## トラブルシューティング

| 症状 | 対処法 |
|------|--------|
| `cortex mcp list` に drawio-app が表示されない | `cortex mcp add drawio-app --sse https://mcp.draw.io/mcp` を再実行 |
| 図がインライン表示されない（テキストで返る） | CoCo のバージョンが MCP Apps 非対応の可能性。drawio（npm 版）を試す |
| npm 版に切り替える場合 | `cortex mcp add drawio -- npx -y @drawio/mcp`（Node.js 必要） |

---

## 参考: mcp.json での手動設定

`.cortex/mcp.json` に直接記述する場合：

```json
{
  "mcpServers": {
    "drawio-app": {
      "type": "sse",
      "url": "https://mcp.draw.io/mcp"
    }
  }
}
```

---

## 講師ポイント

- **MCPとは**: Model Context Protocol の略。CoCoが外部ツールと連携するための標準プロトコル
- **drawio-app の特徴**: 公式ホスト（`mcp.draw.io`）に接続するだけ。インストール不要でチャット内に図が描かれる
- **draw.io以外のMCP**: GitHub・Jira・Slack など様々なMCPが利用可能
- **活用価値**: データ全体像のドキュメント化がCoCoとの会話だけで瞬時にできる
