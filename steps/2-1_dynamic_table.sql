-- Step1: ロールとウェアハウスの設定
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE SCHEMA SNOWRETAIL_DB.SNOWRETAIL_SCHEMA;

-- Step2: ベーステーブルの Change Tracking を有効化
ALTER TABLE SNOWRETAIL_DB.SNOWRETAIL_SCHEMA.EC_DATA SET CHANGE_TRACKING = TRUE;
ALTER TABLE SNOWRETAIL_DB.SNOWRETAIL_SCHEMA.RETAIL_DATA SET CHANGE_TRACKING = TRUE;
ALTER TABLE SNOWRETAIL_DB.SNOWRETAIL_SCHEMA.PRODUCT_MASTER SET CHANGE_TRACKING = TRUE;

-- Step3: Dynamic Table MART_SALES の作成
CREATE OR REPLACE DYNAMIC TABLE SNOWRETAIL_DB.SNOWRETAIL_SCHEMA.MART_SALES
  TARGET_LAG = '1 hour'
  WAREHOUSE = COMPUTE_WH
  REFRESH_MODE = AUTO
  INITIALIZE = ON_CREATE
  AS
    WITH all_sales AS (
        SELECT
            TRANSACTION_ID,
            TRANSACTION_DATE,
            'EC' AS CHANNEL,
            PRODUCT_ID,
            QUANTITY,
            UNIT_PRICE,
            TOTAL_PRICE
        FROM SNOWRETAIL_DB.SNOWRETAIL_SCHEMA.EC_DATA
        UNION ALL
        SELECT
            TRANSACTION_ID,
            TRANSACTION_DATE,
            'RETAIL' AS CHANNEL,
            PRODUCT_ID,
            QUANTITY,
            UNIT_PRICE,
            TOTAL_PRICE
        FROM SNOWRETAIL_DB.SNOWRETAIL_SCHEMA.RETAIL_DATA
    )
    SELECT
        s.TRANSACTION_ID,
        s.TRANSACTION_DATE,
        s.CHANNEL,
        s.PRODUCT_ID,
        m.PRODUCT_NAME,
        CASE
            WHEN m.PRODUCT_NAME RLIKE '.*(テレビ|CRYSTALVIEW|VISIONMAX|CLEARSCREEN|BRIGHTVIEW|LED.*PRO|LEDテレビ|ビエラ|サイネージ).*' THEN 'テレビ・ディスプレイ'
            WHEN m.PRODUCT_NAME RLIKE '.*(カメラ|一眼|α7|EOS|X-T4|PEN-F|Z6|OM-D).*' THEN 'カメラ'
            WHEN m.PRODUCT_NAME RLIKE '.*(プロジェクター).*' THEN 'プロジェクター'
            WHEN m.PRODUCT_NAME RLIKE '.*(エアコン|MSZ|CS-XE).*' THEN 'エアコン'
            WHEN m.PRODUCT_NAME RLIKE '.*(冷蔵庫|ノンフロン|NR-F).*' THEN '冷蔵庫'
            WHEN m.PRODUCT_NAME RLIKE '.*(洗濯機|ドラム式).*' THEN '洗濯機'
            WHEN m.PRODUCT_NAME RLIKE '.*(掃除機).*' THEN '掃除機'
            WHEN m.PRODUCT_NAME RLIKE '.*(炊飯器|IH|電子レンジ).*' THEN '調理家電'
            WHEN m.PRODUCT_NAME RLIKE '.*(加湿器|空気清浄機).*' THEN '空調・空気清浄'
            WHEN m.PRODUCT_NAME RLIKE '.*(ヘッドホン|スピーカー|ブルーレイ).*' THEN 'AV・オーディオ'
            WHEN m.PRODUCT_NAME RLIKE '.*(スマートウォッチ|スマートフォン).*' THEN 'スマートデバイス'
            WHEN m.PRODUCT_NAME RLIKE '.*(ゲーム|GAMESTATION).*' THEN 'ゲーム'
            WHEN m.PRODUCT_NAME RLIKE '.*(ノートパソコン|ValueBook).*' THEN 'パソコン'
            WHEN m.PRODUCT_NAME RLIKE '.*(プリン|スキャナー|imagePROGRAF|PIXMA|TASKalfa|IM C|MP C|DS-300).*' THEN 'プリンター・複合機'
            WHEN m.PRODUCT_NAME RLIKE '.*(カップめん|うどん|ラーメン|麺|カレールウ).*' THEN '食品・インスタント'
            WHEN m.PRODUCT_NAME RLIKE '.*(ビール|ジュース|飲料|牛乳|ヨーグルト|ヘルス1000).*' THEN '飲料・乳製品'
            WHEN m.PRODUCT_NAME RLIKE '.*(チョコ|製菓|スイーツ).*' THEN 'お菓子'
            WHEN m.PRODUCT_NAME RLIKE '.*(洗剤|柔軟剤|シャンプー|ケア|クリーム|リリーフ|ソフティーナ).*' THEN '日用品・ヘルスケア'
            WHEN m.PRODUCT_NAME RLIKE '.*(シャツ|ジーンズ|コート|パーカー|ジャケット|Tシャツ|ワンピース|ウェア).*' THEN '衣料品'
            WHEN m.PRODUCT_NAME RLIKE '.*(ペン|文具|ノート|ハイライター|消しゴム|シャープ).*' THEN '文具'
            WHEN m.PRODUCT_NAME RLIKE '.*(トイ|フィギュア|ミニカー|レーサー|カード|トレイン|デジペット|ロボ|ヒーロー).*' THEN 'おもちゃ'
            WHEN m.PRODUCT_NAME RLIKE '.*(スノーフレッシュ|有機|卵|豆腐|食パン).*' THEN '生鮮・PB食品'
            WHEN m.PRODUCT_NAME RLIKE '.*(スノーセレクト|和牛|豚肉|地鶏|鮮魚|刺身|惣菜).*' THEN '精肉・鮮魚・惣菜'
            WHEN m.PRODUCT_NAME RLIKE '.*(スノーデリ|キット|セット|炊き込み).*' THEN 'ミールキット'
            ELSE 'その他'
        END AS CATEGORY,
        s.QUANTITY,
        s.UNIT_PRICE,
        s.TOTAL_PRICE
    FROM all_sales s
    JOIN SNOWRETAIL_DB.SNOWRETAIL_SCHEMA.PRODUCT_MASTER m
        ON s.PRODUCT_ID = m.PRODUCT_ID;
