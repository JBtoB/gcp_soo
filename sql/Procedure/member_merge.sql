CREATE OR REPLACE PROCEDURE `looker_procedure.member_merge`()
BEGIN
CREATE OR REPLACE TABLE `looker.member_source_tmp` AS (
      SELECT
        member_code,
        sex,
        birthyear,
        zip,
        belong,
        SAFE.PARSE_DATE('%Y%m%d',
          CAST(admission_date AS STRING)) AS admission_date,
        dummy
      FROM
        looker.member_source);
        
    MERGE
      `looker.member` AS m2
    USING
      `looker.member_source_tmp` AS m1
    ON
      m1.member_code = m2.member_code
      WHEN MATCHED THEN UPDATE SET
        m2.sex = m1.sex, 
        m2.birthyear = m1.birthyear,
        m2.zip = m1.zip,
        m2.belong = m1.belong,
        m2.admission_date = m1.admission_date,
        m2.dummy = m1.dummy
      WHEN NOT MATCHED
      THEN
    INSERT
      (member_code,sex,birthyear,zip,belong,admission_date,dummy)
    VALUES
      (member_code,sex,birthyear,zip,belong,admission_date,dummy);
END;      