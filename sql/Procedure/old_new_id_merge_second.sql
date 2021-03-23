CREATE OR REPLACE PROCEDURE `looker_procedure.old_new_id_merge_second`()
BEGIN
    # 1 2
    # 2 3  
    # の場合に
    # 1 3
    # 2 3
    # に洗替する処理
    MERGE looker.old_new_id id1
      USING looker.old_new_id id2
        ON id1.new_ID = id2.old_ID 
      WHEN MATCHED
      THEN
      UPDATE SET
      id1.new_ID = id2.new_ID;
END; 