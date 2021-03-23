CREATE OR REPLACE PROCEDURE `looker_procedure.transaction_source_merge`()
BEGIN    
    # 新旧IDによる中間売上データの洗替
    UPDATE
      `looker.transaction_source` AS tran
    SET
      tran.member = id.new_ID
    FROM
      `looker.old_new_id` AS id
    WHERE
      tran.member = id.old_ID;
END;    