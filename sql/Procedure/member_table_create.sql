CREATE OR REPLACE PROCEDURE `looker_procedure.member_table_create`()

BEGIN
 # memberテーブルがない場合には作成

    CREATE TABLE IF NOT EXISTS `looker.member`
      (
      member_code STRING,
      sex STRING,
      birthyear INT64,
      zip STRING,
      belong STRING,
      admission_date DATE,
      dummy STRING);
END;      