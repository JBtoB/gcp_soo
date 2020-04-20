# standard SQL
# プロシージャを使用
# retry用のSQL: sql_procedure.sqlが失敗したときに、同様の処理を行う


    # janテーブルがない場合には作成
    CALL looker_procedure.jan_table_create();

    # 洗替のために、janの中間テーブルを使用してjanテーブルに対してMERGE処理をする
    CALL looker_procedure.jan_merge();

    # memberテーブルがない場合には作成
    CALL looker_procedure.member_table_create();

    # 洗替のために、memberの中間テーブルを使用してmemberテーブルに対してMERGE処理をする
    CALL looker_procedure.member_merge();

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

    CALL looker_procedure.update_table_create();
    CALL looker_procedure.insert_update();
