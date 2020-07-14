CREATE OR REPLACE PROCEDURE `looker_procedure.create_new_old_id`()
BEGIN  
    CREATE OR REPLACE TABLE
      `looker.old_new_id`
      AS
    SELECT DISTINCT
      old_ID,
      new_ID,
      dummy
    FROM
      looker.old_new_id_source;
END;      