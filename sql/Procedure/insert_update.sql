CREATE OR REPLACE PROCEDURE `looker_procedure.insert_update`()
BEGIN    
    # 最後にupdate テーブルに現在の時間をインサート
    # この部分のみJSTに準じた時間にしている
    INSERT  `looker.update`
    (update_timestamp)
    VALUES
    (TIMESTAMP_ADD(CURRENT_TIMESTAMP, INTERVAL 9 hour));
END;    