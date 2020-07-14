CREATE OR REPLACE PROCEDURE `looker_procedure.retry`(INOUT check_error STRING, INOUT job_state STRING)
BEGIN

# ひとつ前のクエリが上手く行ったかを確認する。
SET (check_error, job_state) =
(
SELECT
    (
    error_result.reason,
    state
    ) 
  FROM
    `region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
  WHERE
    statement_type = 'SCRIPT'
    AND job_type = 'QUERY'
  ORDER BY
    start_time DESC
  LIMIT 1
  OFFSET 1 # 今回の実行を除外するため
);
END;