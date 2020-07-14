CREATE OR REPLACE PROCEDURE `looker_procedure.transaction_summary`()
BEGIN  

    CREATE OR REPLACE TABLE `looker.transaction_summary` AS
    SELECT 
    DATE(TIMESTAMP_ADD(purchase_timestamp, INTERVAL 9 HOUR)) AS purchase_date,
    SUM(amount) AS amount_daily,
    COUNT(purchase_date) AS count_number
    FROM `looker.transaction` 
    WHERE 
    # 実行日から過去10日のデータのみを対象とするように指定
    DATE(TIMESTAMP_ADD(purchase_timestamp, INTERVAL 9 HOUR)) <= CURRENT_DATE("Asia/Tokyo")
    AND DATE(TIMESTAMP_ADD(purchase_timestamp, INTERVAL 9 HOUR)) >= DATE_SUB(CURRENT_DATE("Asia/Tokyo"), INTERVAL 10 day)
    GROUP BY 
    purchase_date
    ORDER BY
    purchase_date DESC;
END;