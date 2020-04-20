CREATE OR REPLACE PROCEDURE `looker_procedure.update_table_create`()
BEGIN        
    # updateテーブルがなければ作成  
    # この部分のみJSTに準じた時間にしている 
    CREATE TABLE IF NOT EXISTS`looker.update` AS
      (SELECT
        TIMESTAMP_ADD(CURRENT_TIMESTAMP, INTERVAL 9 hour)  AS update_timestamp
      );
END;      