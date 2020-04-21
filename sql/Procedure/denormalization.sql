CREATE OR REPLACE PROCEDURE `looker_procedure.denormalization`()
BEGIN    
    # 非正規化テーブルの作成、もし必要なくなった場合にはこの部分を削除
    CREATE OR REPLACE TABLE
      `looker.denormalization`
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
      `looker.transaction` AS tran
    LEFT JOIN
      `looker.member` AS master_member
    ON
      tran.member = master_member.member_code
    LEFT JOIN
      `looker.jan` AS master_jan
    on tran.jan_code = master_jan.jan_code
    LEFT JOIN
      `looker.item` AS master_item
    ON
      master_jan.item_code = master_item.item_code
    LEFT JOIN
      `looker.office` AS master_office
    ON
      tran.office = master_office.office_code
    LEFT JOIN
      `looker.maker` AS master_maker
    ON
      master_jan.maker_code =master_maker.maker_code
    LEFT JOIN
      `looker.brand` AS master_brand
    ON
      master_jan.brand_code = master_brand.brand_code
    LEFT JOIN
      `looker.SOO_item` AS master_SOO_item
    ON
      master_jan.SOO_item = master_SOO_item.soo_code;
END;    