CREATE OR REPLACE PROCEDURE `looker_procedure.jan_table_create`()
BEGIN
# janテーブルがない場合には作成
    CREATE TABLE IF NOT EXISTS `looker.jan`
    (
    jan_code STRING,
    jan_name STRING,
    item_code STRING,
    jbtob_chk STRING,
    maker_code STRING,
    brand_code STRING,
    SOO_item STRING,
    dummy STRING
    );
END;  