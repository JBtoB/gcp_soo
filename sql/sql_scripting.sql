# standard SQL

# 変数の宣言
DECLARE check_member_exist, check_jan_exist, check_update_exist INT64;

# memberテーブルが存在するかの確認用
SET 
  check_member_exist =(
    SELECT size_bytes
    FROM pos_analysis.__TABLES__ 
    WHERE table_id='member'
  );

# janテーブルが存在するかの確認用
SET 
  check_jan_exist = (
    SELECT size_bytes
    FROM pos_analysis.__TABLES__ 
    WHERE table_id='jan'
  );

# updateテーブルが存在するかの確認用
SET 
  check_update_exist = (
    SELECT size_bytes
    FROM pos_analysis.__TABLES__ 
    WHERE table_id='update'
  );

# ひとつ前の同じSQLが正常に終了した場合には以下の処理を行わず、
#エラーが起きていた場合には、洗替処理を再度行う   
    # janテーブルがない場合には作成
    IF (check_jan_exist is null)
        THEN
          CREATE TABLE `pos_analysis.jan`
            (
              jan_code STRING,
              jan_name STRING,
              item_code STRING,
              jbtob_chk STRING,
              maker_code STRING,
              brand_code STRING,
              SOO_item STRING,
              dummy STRING
              );
    END IF;  
    
    # 洗替のために、janの中間テーブルを使用してjanテーブルに対してMERGE処理をする
    MERGE
      `pos_analysis.jan` AS j2
    USING
      `pos_analysis.jan_source` AS j1
    ON
      j1.jan_code = j2.jan_code
      WHEN MATCHED THEN UPDATE SET 
        j2.jan_name = j1.jan_name,
        j2.item_code = j1.item_code,
        j2.jbtob_chk = j1.jbtob_chk,
        j2.maker_code = j1.maker_code,
        j2.brand_code = j1.brand_code,
        j2.SOO_item = j1.SOO_item,
        j2.dummy = j1.dummy
      WHEN NOT MATCHED
      THEN
    INSERT
      (jan_code,
        item_code,
        jbtob_chk,
        maker_code,
        brand_code,
        SOO_item,
        dummy)
    VALUES
      (jan_code,item_code,jbtob_chk,maker_code,brand_code,SOO_item,dummy);
      
      # memberテーブルがない場合には作成
      IF check_member_exist is null
        THEN
          CREATE TABLE `pos_analysis.member`
            (
              member_code STRING,
              sex STRING,
              birthyear INT64,
              zip STRING,
              belong STRING,
              admission_date DATE,
              dummy STRING);
      END IF;
    
    CREATE OR REPLACE TABLE `pos_analysis.member_source` AS (
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
        pos_analysis.member_source);
        
    MERGE
      `pos_analysis.member` AS m2
    USING
      `pos_analysis.member_source` AS m1
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
    
    # idの整合性を保つための処理。2段階に分けているが、もっとよいやり方ないかを探す。
    # 1 2
    # 1 3  
    # の場合に大きい数の方が真なので、
    # 1 3 のみを残すように処理
    MERGE pos_analysis.old_new_id id1
      USING pos_analysis.old_new_id id2
        ON id1.old_ID = id2.old_ID 
      WHEN MATCHED AND id1.new_ID < id2.new_ID
      THEN
      DELETE;

    
    # 1 2
    # 2 3  
    # の場合に大きい数の方が真なので、
    # 1 3
    # 2 3
    # に洗替する処理
    MERGE pos_analysis.old_new_id id1
      USING pos_analysis.old_new_id id1
        ON id1.new_ID = id2.old_ID 
      WHEN MATCHED AND id1.new_ID < id2.new_ID
      THEN
      UPDATE SET
      id1.new_ID = id2.new_ID;
    
    # 新旧IDによる売上データの洗替
    UPDATE
      `pos_analysis.transaction_source` AS tran
    SET
      tran.member = id.new_ID
    FROM
      `pos_analysis.old_new_id` AS id
    WHERE
      tran.member = id.old_ID
      AND id.old_ID < id.new_ID;
    
    # 中間テーブルから売上テーブルを作成
    CREATE OR REPLACE TABLE
      `pos_analysis.transaction`
    PARTITION BY
      DATE(purchase_timestamp) 
      AS
    SELECT
      PARSE_TIMESTAMP('%Y%m%d%H%M%S', CONCAT(purchase_date, purchase_time)) AS purchase_timestamp,
      PARSE_DATE('%Y%m%d',
        purchase_date) AS purchase_date,
      PARSE_TIME('%H%M%S',
        purchase_time) AS purchase_time,
      office,
      member,
      jan_code,
      amount,
      quantity,
      profit,
      posnumber,
      sheetnumber,
      dummy
    FROM
      pos_analysis.transaction_source;
    
    # 非正規化テーブルの作成、もし必要なくなった場合にはこの部分を削除
    CREATE OR REPLACE TABLE
      `pos_analysis.denormalization`
    PARTITION BY
      DATE(purchase_timestamp) AS
    SELECT
      tran.* EXCEPT(office,member,jan_code,dummy),
      master_member.* EXCEPT(dummy),
      master_jan.* EXCEPT(item_code,maker_code,brand_code,SOO_item,dummy),
      master_item.* EXCEPT(dummy),
      master_office.* EXCEPT(dummy),
      master_maker.* EXCEPT(dummy),
      master_brand.* EXCEPT(dummy),
      master_SOO_item.* EXCEPT(dummy)
    FROM
      `pos_analysis.transaction` AS tran
    LEFT JOIN
      `pos_analysis.member` AS master_member
    ON
      tran.member = master_member.member_code
    LEFT JOIN
      `pos_analysis.jan` AS master_jan
    USING
      (jan_code)
    LEFT JOIN
      `pos_analysis.item` AS master_item
    ON
      master_jan.item_code = master_item.item_code
    LEFT JOIN
      `pos_analysis.office` AS master_office
    ON
      tran.office = master_office.office_code
    LEFT JOIN
      `pos_analysis.maker` AS master_maker
    ON
      master_jan.maker_code =master_maker.maker_code
    LEFT JOIN
      `pos_analysis.brand` AS master_brand
    ON
      master_jan.brand_code = master_brand.brand_code
    LEFT JOIN
      `pos_analysis.SOO_item` AS master_SOO_item
    ON
      master_jan.SOO_item = master_SOO_item.soo_code;
      
    # updateテーブルがなければ作成
    # この部分のみJSTに準じた時間にしている
    IF check_update_exist is null
      THEN  
        CREATE OR REPLACE TABLE `pos_analysis.update` AS
        (SELECT
          TIMESTAMP_ADD(CURRENT_TIMESTAMP, INTERVAL 9 hour)  AS update_timestamp
        );
    ELSE
        # 最後にupdate テーブルに現在の時間をインサート
        # この部分のみJSTに準じた時間にしている
        INSERT  `pos_analysis.update`
        (update_timestamp)
        VALUES
        (TIMESTAMP_ADD(CURRENT_TIMESTAMP, INTERVAL 9 hour));
    END IF;