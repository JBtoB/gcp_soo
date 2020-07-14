CREATE OR REPLACE PROCEDURE `looker_procedure.scripting_procedure`()
BEGIN 

    # standard SQL
    # プロシージャを使用

    # janテーブルがない場合には作成
    CALL looker_procedure.jan_table_create();
    
    # 中間テーブルjan_source でjan_codeが重複するものがあった場合に1レコードをのみを残す
    CALL looker_procedure.jan_delete_duplication();

    # 洗替のために、janの中間テーブルを使用してjanテーブルに対してMERGE処理をする
    CALL looker_procedure.jan_merge();

    # memberテーブルがない場合には作成
    CALL looker_procedure.member_table_create();
    
    # 中間テーブルmember_source でmember_codeが重複するものがあった場合に1レコードをのみを残す
    CALL looker_procedure.member_delete_duplication();

    # 洗替のために、memberの中間テーブルを使用してmemberテーブルに対してMERGE処理をする
    CALL looker_procedure.member_merge();

    # 重複のある行の除外
    CALL `looker_procedure.create_new_old_id`();

    # 1 2
    # 1 3  
    # の場合に大きい数の方が真なので、
    # 1 3 のみを残すように処理
    CALL looker_procedure.old_new_id_merge_first();

    # 1 2
    # 2 3  
    # の場合に大きい数の方が真なので、
    # 1 3
    # 2 3
    # に洗替する処理
    CALL looker_procedure.old_new_id_merge_second();

    # 新旧IDによる中間売上データの洗替
    CALL looker_procedure.transaction_source_merge();

    # 中間テーブルから売上テーブルを作成
    CALL looker_procedure.transaction_create();

    # 非正規化テーブルの作成、もし必要なくなった場合にはこの部分を削除
    # 非正規テーブルを作成しないので、下記の処理をコメントアウト
    # 既存テーブルのみで非正規化テーブルを作成する場合には、下記の処理を実行すれば良い。
    #CALL looker_procedure.denormalization();
    
    # transaction テーブルの過去10日分のサマリーテーブルを作成
    # 合計料金、更新件数が記載されている
    CALL looker_procedure.transaction_summary();
    
    # update_tableの更新
    # looker のキャッシュは、update_tableを利用している。
    CALL looker_procedure.update_table_create();
    CALL looker_procedure.insert_update();
    
    # 当SQLのどこかでエラーが起き、処理が中断した場合の例外処理
    # transaction テーブルへのmember IDの洗い替え、transaction テーブルの更新
    EXCEPTION WHEN ERROR THEN
      CALL looker_procedure.old_new_id_merge_first();
      CALL looker_procedure.old_new_id_merge_second();
      
      
      # 新旧IDによる中間売上データの洗替
      CALL looker_procedure.transaction_source_merge();

      # 中間テーブルから売上テーブルを作成
      CALL looker_procedure.transaction_create();
      
      # transaction テーブルの過去10日分のサマリーテーブルを作成
      # 合計料金、更新件数が記載されている
      CALL looker_procedure.transaction_summary();
      
      # update_tableの更新
      # looker のキャッシュは、update_tableを利用している。
      CALL looker_procedure.update_table_create();
      CALL looker_procedure.insert_update();
    
END;
