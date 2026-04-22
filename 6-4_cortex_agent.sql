CREATE OR REPLACE AGENT SNOWRETAIL_DB.SNOWRETAIL_SCHEMA.SNOWRETAIL_HANDSON_AGENT
FROM SPECIFICATION $$
{
  "models": {
    "orchestration": "auto"
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "query_snowretail",
        "description": "売上データやレビューデータに対する自然言語での問い合わせを、SQLに変換して実行します。カテゴリ別売上、チャネル比較、月次推移、商品評価などの分析が可能です。"
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "search_docs",
        "description": "社内ドキュメント（業務マニュアル、FAQ、運用ガイドなど）を検索します。データの定義や業務ルールに関する質問に回答します。"
      }
    }
  ],
  "tool_resources": {
    "query_snowretail": {
      "execution_environment": {
        "query_timeout": 299,
        "type": "warehouse",
        "warehouse": ""
      },
      "semantic_view": "SNOWRETAIL_DB.SNOWRETAIL_SCHEMA.SNOWRETAIL_SV"
    },
    "search_docs": {
      "execution_environment": {
        "query_timeout": 299,
        "type": "warehouse",
        "warehouse": ""
      },
      "search_service": "SNOWRETAIL_DB.SNOWRETAIL_SCHEMA.HANDSON_DOCS_SEARCH"
    }
  }
}
$$;
