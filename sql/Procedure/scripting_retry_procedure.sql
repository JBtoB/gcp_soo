CREATE OR REPLACE PROCEDURE `looker_procedure.scripting_retry_procedure`()

BEGIN
    # standard SQL
    # プロシージャを使用
    # retry用のSQL scripting_procedure.sqlが失敗したときに、同様の処理を行う

    # 変数の宣言
    DECLARE check_error, job_state STRING;
    # ひとつ前のスクリプトによるクエリが上手く行ったかを確認する。
    CALL looker_procedure.retry(check_error,job_state);

    # ひとつ前の同じSQLが正常に終了した場合には以下の処理を行わず、
    # エラーが起きていた場合には、洗替処理を再度行う
    IF (check_error is not null
    OR job_state != 'DONE')
    THEN

        CALL looker_procedure.scripting_procedure();
        
    END IF;
END;