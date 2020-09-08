'''
Cloud FuctionsのGCSトリガーを利用して、
GCSのgzipファイルをBigQueryにロードする。
GCSにはスキーマファイルと設定ファイルを用意し
それを利用し読み込む。
'''

from google.cloud import bigquery, storage
import json
import logging
import os


def main(event, context):

    # -----------------------------------------------環境変数
    project_id = get_enviroment_value("GCP_PROJECT")
    # -----------------------------------------------
    # -----------------------------------------------変数
    # GCS Objectのサイズの閾値
    size_threshold = 100
    # -----------------------------------------------

    bucket_name = event["bucket"]
    file_name = event["name"]
    file_size = event["size"]

    # アップロードされたGCS Objectのサイズが100bytes以下のときアラートログを出力
    check_file_size(file_name, file_size, size_threshold)

    # アップロードされたGCS ObjectがBigQueryにアップロードするものかのチェック
    uri = valid_dir(bucket_name, file_name)

    # GCS上の設定ファイルとスキーマファイルを取得
    schema, config, kind_name, update_date = check_setting_files_exist(bucket_name,file_name)

    # GCS上の設定ファイルとスキーマファイルを利用して、ロードジョブの設定を行う
    load_job_config = bigquery.LoadJobConfig()
    job_config, dataset_id, table_id = setting_options(load_job_config, schema, config, kind_name, update_date)

    # 書き込み先のBQのDatasetが存在するかの確認。なければ作成する。
    client = bigquery.Client(project_id)
    create_dataset(client, dataset_id)
    dataset = client.dataset(dataset_id)

    # ロードジョブの設定
    load_job = client.load_table_from_uri(
        uri, dataset.table(table_id), job_config=job_config
    )
    load_job.running()


def check_setting_files_exist(bucket_name,file_name):
    """
     GCSにあるconfig.jsonとschema.jsonがあるかを確認、
     確認後に取得する。

     Args:
       bucket_name (STRING): GCSトリガーに設定されているバケット
       file_name (STRING): GCSで更新があったファイルのベケット以下のパス
     Returns:
       schema (dict): GCSから読み込んだBigQueryのスキーマ
       config (dict): GCSから読み込んだBigQueryロードの設定
       kind_name (STRING): データの種名
       update_date (STRING): ファイルの連携日
     """

    # -----------------------------------------------環境変数
    project_id = get_enviroment_value("GCP_PROJECT")
    # -----------------------------------------------

    # 拡張子部分を除いたデータ種名と差分更新ファイルの場合には日付部分も抽出
    name = file_name.split('/',1)[1].split('.',1)
    if "diff_" in name[0]:
        kind_name = name[0].strip('diff_').rsplit('_',1)[0]
        update_date = name[0].split('_')[2]
    else:
        kind_name = name[0]
        update_date = None

    # bq loadでの設定ファイルがあるバケット名を取得
    setting_bucket_name = "{}-setting".format(bucket_name)

    storage_client = storage.Client(project_id)
    bucket = storage_client.get_bucket(setting_bucket_name)

     # 設定ファイルとスキーマファイルのGCS パスの設定
    schema_blob = bucket.blob("settings/{}/schema.json".format(kind_name))
    config_blob = bucket.blob("settings/{}/config.json".format(kind_name))

    # スキーマファイルが存在するかの確認。あればファイルを取得し、なければエラーを吐く。
    if schema_blob.exists():
        schema_json = schema_blob.download_as_string()
    else:
        logging.error("Schema file is not existed in gs://{}/settings/{}/schema.json. Please check file path".format(setting_bucket_name, kind_name))

    # ロードジョブの設定ファイルが存在するかの確認。あればファイルを取得し、なければエラーを吐く。
    if config_blob.exists():
        config_json = config_blob.download_as_string()
    else:
        logging.error("Config file is not existed in gs://{}/settings/{}/config.json. Please check file path".format(setting_bucket_name, kind_name))

    schema = json.loads(schema_json)
    config = json.loads(config_json)

    return schema, config, kind_name, update_date


def create_dataset(client, dataset):
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
    except:
        # データセットがない場合は新たに作成する。
        bigquery_client = bigquery.Dataset(dataset_ref)
        create_dataset = client.create_dataset(bigquery_client)

    return

def setting_options(load_job_config, schema, config, kind_name, update_date):
    """
     GCSにあるconfig.jsonとschema.jsonを取得・利用し、
     BigQueryのロードジョブの設定を行う。

     Args:
       load_job_config (google.cloud.bigquery.job.LoadJobConfig): BigQueryへのロードに使用する設定
       config (dict): GCSから読み込んだBigQueryロードの設定
       schema (dict): GCSから読み込んだBigQueryのスキーマ
       kind_name (STRING): データの種類
       update_date (STRING): ファイル連携日
     Returns:
       job_config (google.cloud.bigquery.job.LoadJobConfig): BigQueryへのロードに使用する設定
       dataset_id (STRING): BigQueryのdatasetID 
       table_id (STRING): BigQueryのtableID 
     """

    new_schema = list()
    # スキーマファイルをインポート
    for i in range(len(schema)):
        try:
            new_schema.append(bigquery.SchemaField(schema[i]["name"], schema[i]["type"], schema[i]["mode"]))
        except:
            new_schema.append(bigquery.SchemaField(schema[i]["name"], schema[i]["type"]))
        

    # 設定ファイルにスキーマを代入
    load_job_config.schema = new_schema
    # config.jsonの設定をインポート
    load_job_config.source_format = config["sourceFormat"]
    load_job_config.autodetect = config["autodetect"]
    load_job_config.create_disposition = config["createDisposition"]
    load_job_config.write_disposition = config["writeDisposition"]
    load_job_config.skip_leading_rows = config["skipLeadingRows"]
    load_job_config.null_marker = config["nullMarker"]
    load_job_config.encoding = config["encoding"]
    load_job_config.max_bad_records = config["maxBadRecords"]
    load_job_config.allow_quoted_newlines = config["allowQuotedNewlines"]
    load_job_config.allow_jagged_rows = config["allowJaggedRows"]
    load_job_config.quote_character = config["quote"]
    load_job_config.ignore_unknown_values = config["ignoreUnknownValues"]

    # BigQueryのデータセット・テーブルIDの取得
    dataset_id = config["destinationTable"]["datasetId"]
    table_id = config["destinationTable"]["tableId"]

    # transactionの場合にはパーティションを作成するので、その設定。
    if (kind_name == "transaction"):
        table_id = "{}${}".format(table_id,update_date)
        load_job_config.time_partitioning = bigquery.TimePartitioning(
            type_=bigquery.TimePartitioningType.DAY
            )

    return load_job_config, dataset_id, table_id  


def valid_dir(bucket, name):
    '''
    GCSトリガーから送られてきたアップロードされたオブジェクトのGCSパスが
    BigQueryロードジョブの対象ファイルかを判定する関数

    Args:
    bucket (STRING) : アップロードされたGCSバケット名
    name (STRING) : アップロードされたオブジェクト名

    Return:
    path (STRING) : アップロードされたオブジェクトのGCSのURI
    '''

    path = "gs://{}/{}".format(bucket, name)
    print(path)
    file_format = name.split(".", 1)
    
    #dataのフォルダに入れているかの確認
    if(name.split("/")[0]) == "data":
        logging.info("Input folder: OK")
    else:
        logging.error("Input Folder: {} is wrong.".format(name.split("/")[0]))

    #csvファイルでgzip圧縮をしているかの確認
    if file_format[1] == "csv.gz":
        logging.info("File format: OK")
    else:
        logging.error("File format: {} is not used.".format(file_format[1]))

    return path


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


def check_file_size(name, size, threshold):
    '''
    GCSにアップロードされたObjectのサイズが閾値以下のときアラートログを出力する関数

    Args:
    name (STRING) : GCSにアップロードされたオブジェクト名
    size (STRING) : GCSにアップロードされたオブジェクトのサイズ
    threshold (int) : サイズの閾値
    '''

    if int(size) <= threshold:
        logging.warning("Size of {} is {} bytes and not greater than threshold of {} bytes.".format(name, size, threshold))

    return
