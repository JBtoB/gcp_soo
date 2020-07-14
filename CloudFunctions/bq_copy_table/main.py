'''
Cloud Scheduler からのHTTPリクエストをトリガーとして、
Looker 接続用のデータセットから、指定したテーブルを
バックアップ用のデータセットにコピーする。
'''

from google.cloud import bigquery, storage
from google.cloud.exceptions import NotFound
import json
import logging
import os


def main(request):

    # -----------------------------------------------環境変数
    project_id = get_enviroment_value("GCP_PROJECT")
    # -----------------------------------------------Schedulerに設定した変数
    source_dataset = get_request_value_or_raise(request,"source_dataset")
    target_dataset = get_request_value_or_raise(request,"target_dataset")
    table_names = get_request_value_or_raise(request, "table_names")
    # -----------------------------------------------
    

    client = bigquery.Client(project_id)

    # コピー先のデータセットがあるかの確認、なければ作成
    create_dataset(client, target_dataset)
   
    # コピージョブの実行
    copy_tables(client, project_id, source_dataset, target_dataset, table_names)


def copy_tables(client, project_id, source_dataset, target_dataset, table_names):
    '''
    テーブルコピーを実施する関数

    Args:
    client (google.cloud.bigquery.client.Client): bigqueryのクライアント
    project_id (STRING): GCPのプロジェクトID
    source_dataset (STRING): コピー元のデータセット名
    target_dataset (STRING): コピー先のデータセット名
    table_names (list): コピーするテーブル名のリスト
    Return:
    None
    '''

    # コピージョブの準備
    job_config = bigquery.CopyJobConfig()
    job_config.write_disposition = "WRITE_TRUNCATE"
    
    #複数テーブルのコピー実施
    for table_name in table_names:
    
        # コピー元とコピー先の名前の作成
        source_table = "{}.{}.{}".format(project_id,source_dataset,table_name)
        target_table = "{}.{}.{}".format(project_id,target_dataset,table_name)
        try:
            # コピー元のテーブルがあるかの確認。なければ、ログに出力
            table_ref = client.dataset(source_dataset).table(table_name)
            table_check = client.get_table(table_ref)
            # コピージョブの作成
            copy_job = client.copy_table(
                source_table,
                target_table,
                job_config=job_config)
            #　コピージョブの実施
            copy_job.result()
        except NotFound:
            logging.info(table_name + " is not exist")
    return    


def  create_dataset(client, dataset):
    '''
    データセットが存在しない場合に作成を行う関数

    Args:
    client (google.cloud.bigquery.client.Client) : bigqueryのクライアント
    dataset(STRING) : dataset名
    Return:
    None
    '''

    dataset_ref = client.dataset(dataset)

    try:
        # 書き込み先であるBigQueryのデータセットが存在するかの確認。
        client.get_dataset(dataset_ref)
        logging.info(dataset + "is already exist")
    except NotFound:
        # データセットがない場合は新たに作成する。
        bigquery_client = bigquery.Dataset(dataset_ref)
        create_dataset = client.create_dataset(bigquery_client)
    return


def get_enviroment_value(name):
    '''
    Cloud Functions上で設定した
    環境変数を取得する関数.
    Args:
    name(STRING) : 環境変数名
    Return:
    env_value(STRING) : 環境変数の値
    '''

    # 環境変数の取得
    env_value = os.getenv(name)

    # 環境変数が存在しない場合の例外処理
    if not env_value:
        logging.error("Enviroment Value {} is not set".format(name))
    return env_value


def get_request_value_or_raise(request, name):
    """
    HTTPリクエストボディのパラメータを取得するためのメソッド。
    もしパラメータが未定義の場合、例外を発生させる。

    Args:
      request (dict): HTTPのリクエストボディ
      name (str): keyの名前
    Return:
      req: valueの値
    """

    req = request.get_json(name)[name]
    logging.info("{}: {}".format(name, req))

    if req is None:
        logging.error("Key `{}` should be set at request body".format(name))
    return req

