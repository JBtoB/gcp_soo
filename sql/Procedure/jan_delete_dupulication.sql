CREATE OR REPLACE PROCEDURE `looker_procedure.jan_delete_duplication`()
BEGIN
    CREATE OR REPLACE TABLE  `looker.jan_source` AS  
    # jan中間テーブルの重複を削除
    # jan_code が一致するレコードを対象に1して、その中の1レコードのみを残すように処理する。
    SELECT 
      * EXCEPT (row_num)
      FROM(
        SELECT 
        ROW_NUMBER() OVER (PARTITION BY jan_code  ORDER BY jan_code DESC) AS row_num
        ,* 
        FROM `looker.jan_source`
        )
        WHERE row_num = 1;
END;