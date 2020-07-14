CREATE OR REPLACE PROCEDURE `looker_procedure.delete_old_data_monthly`()
BEGIN 

    # 売上中間テーブルにある27ヶ月以前のデータを削除
    DELETE `looker.transaction_source`
    WHERE 
　    #過去27ヶ月のデータより古いデータを削除するように指定。もしさらに古いデータも残したい場合には INTERVAL 〜 MONTH 間の数字を変更する。
     #この数字が過去何ヶ月分を残すかを指定している。
     TIMESTAMP_SUB(PARSE_TIMESTAMP('%Y%m%d%H%M%S', CONCAT(purchase_date, purchase_time)), INTERVAL 9 hour) < 
     TIMESTAMP(DATE_SUB(DATE_TRUNC(CURRENT_DATE("Asia/Tokyo"), MONTH), INTERVAL 27 MONTH)); 
END;