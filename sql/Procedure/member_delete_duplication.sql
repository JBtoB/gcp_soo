CREATE OR REPLACE PROCEDURE `looker_procedure.member_delete_duplication`()
BEGIN
    
    # member中間テーブルの重複を削除
    # member_code が一致するレコードを対象にして、その中の1レコードのみを残すように処理する。
    CREATE OR REPLACE TABLE  `looker.member_source` AS  
    SELECT 
        * EXCEPT (row_num)
    FROM(
        SELECT 
            ROW_NUMBER() OVER (PARTITION BY member_code  ORDER BY member_code DESC) AS row_num
            ,* 
        FROM `looker.member_source`
    )
    WHERE row_num = 1;
END;