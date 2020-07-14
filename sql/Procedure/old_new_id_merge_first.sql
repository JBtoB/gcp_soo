CREATE OR REPLACE PROCEDURE `looker_procedure.old_new_id_merge_first`()
BEGIN
# idの整合性を保つための処理。2段階に分けているが、もっとよいやり方ないかを探す。
    # 1 2
    # 1 3  
    # の場合に大きい数の方が真なので、
    # 1 3 のみを残すように処理
    MERGE looker.old_new_id id1
      USING looker.old_new_id id2
        ON id1.old_ID = id2.old_ID 
      WHEN MATCHED AND id1.new_ID < id2.new_ID
      THEN
      DELETE;
END;      