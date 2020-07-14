# 売上テーブルにある26ヶ月以前のデータを削除
#DELETE `pos_analysis.transaction`
#WHERE 
#DATE(purchase_timestamp) < DATE_SUB(DATE_TRUNC(CURRENT_DATE("Asia/Tokyo"), MONTH), INTERVAL 26 MONTH);

# 売上中間テーブルにある26ヶ月以前のデータを削除
DELETE `looker.transaction_source`
WHERE 
PARSE_DATE('%Y%m%d', purchase_date) < DATE_SUB(DATE_TRUNC(CURRENT_DATE("Asia/Tokyo"), MONTH), INTERVAL 26 MONTH);