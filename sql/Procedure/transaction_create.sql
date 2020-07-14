CREATE OR REPLACE PROCEDURE `looker_procedure.transaction_create`()
BEGIN    
    # 中間テーブルから売上テーブルを作成
    CREATE OR REPLACE TABLE
      `looker.transaction`
    PARTITION BY
      DATE(purchase_timestamp) 
      AS
    SELECT
      PARSE_TIMESTAMP('%Y%m%d%H%M%S', CONCAT(purchase_date, purchase_time)) AS purchase_timestamp,
      PARSE_DATE('%Y%m%d',
        purchase_date) AS purchase_date,
      PARSE_TIME('%H%M%S',
        purchase_time) AS purchase_time,
      office,
      member,
      jan_code,
      amount,
      quantity,
      profit,
      posnumber,
      sheetnumber,
      dummy
    FROM
      looker.transaction_source;
END;      