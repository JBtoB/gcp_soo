CREATE OR REPLACE PROCEDURE `looker_procedure.jan_merge`()

BEGIN
# 洗替のために、janの中間テーブルを使用してjanテーブルに対してMERGE処理をする
    MERGE
      `looker.jan` AS j2
    USING
      `looker.jan_source` AS j1
    ON
      j1.jan_code = j2.jan_code
      WHEN MATCHED THEN UPDATE SET 
        j2.jan_name = j1.jan_name,
        j2.item_code = j1.item_code,
        j2.jbtob_chk = j1.jbtob_chk,
        j2.maker_code = j1.maker_code,
        j2.brand_code = j1.brand_code,
        j2.SOO_item = j1.SOO_item,
        j2.dummy = j1.dummy
      WHEN NOT MATCHED
      THEN
    INSERT
      (jan_code,
      jan_name,
        item_code,
        jbtob_chk,
        maker_code,
        brand_code,
        SOO_item,
        dummy)
    VALUES
      (jan_code,jan_name,item_code,jbtob_chk,maker_code,brand_code,SOO_item,dummy);
END;