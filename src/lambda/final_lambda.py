import json
import os
from datetime import datetime, timezone
import pg8000.native
import boto3
from boto3.dynamodb.conditions import Key

# RDS
HOST = os.environ.get("host")
PORT = int(os.environ.get("port", 5432))
USER = os.environ.get("user")
PASSWORD = os.environ.get("password")
DATABASE = os.environ.get("database")
TABLE_MAP = {
    "GRN": "grn_daily_main",
    "PUR": "pur_order_daily_main",
    "ISSUE": "issue_daily_main"
}

# S3
BUCKET_NAME = os.environ.get("bucket_name", "shubhra-demo-s3-v001")
REGION = os.environ.get("aws_region", "ap-south-1")

# DynamoDB
dynamodb= boto3.resource("dynamodb")
dynamo_table= os.environ.get('dynamo_table', 'dynamoDb-watermarks')
table= dynamodb.Table(dynamo_table)

con = None
def get_connection():
    global con
    if con is None:
        con = pg8000.native.Connection(
            host=HOST,
            port=PORT,
            user=USER,
            password=PASSWORD,
            database=DATABASE,
            timeout=15
        )
    return con

def get_latest_watermark(feed_id):
    response = table.query(
        KeyConditionExpression=Key("id").eq(feed_id),
        ScanIndexForward=False,  # Descending order
        Limit=1
    )

    items = response.get("Items", [])
    if not items:
        return {"date": "1970-01-01T00:00:00", "last_id": 0}  # Lower Limit

    latest_item = items[0]
    return latest_item

def append_watermark(feed_id, last_ts, last_id, s3_key, record_count):
    table.put_item(
        Item={
            "id": feed_id,
            "date": last_ts,
            "last_id": last_id,
            "s3_key": s3_key,
            "record_count": record_count
        }
    )

def lambda_handler(event, context):
    row_limit= event.get("row_limit", 100)
    process= event.get("process")
    if process== None or process not in TABLE_MAP:
        return {
            "statusCode": 400,
            "body": json.dumps({"message": "Invalid or missing 'process' parameter."}, default=str),
        }

    now= datetime.now(timezone.utc)
    timestamp_str = now.strftime("%Y%m%dT%H%M%S")
    s3_key_process= f"elt_rds_dumps/{process}/year={now:%Y}/month={now:%m}/dump_{timestamp_str}.csv"
    last_watermark= get_latest_watermark(process)
    rds_table= TABLE_MAP.get(process)

    con = get_connection()
    try:
        con.run("BEGIN")

        con.run(
            "CREATE TEMP TABLE temp_batch ON COMMIT DROP AS "
            "SELECT * FROM " + rds_table + " "
            "WHERE (last_updated, id) > (:last_ts, :last_id) "
            "ORDER BY last_updated, id LIMIT :row_limit",
            last_ts=last_watermark["date"], last_id=last_watermark["last_id"], row_limit=row_limit,
        )
        batch_count = con.run("SELECT COUNT(*) FROM temp_batch;")[0][0]
        if batch_count== 0:
            con.run("COMMIT")
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "message": f"No new data to export for {process}.",
                    "s3_key": "/",
                    "new_watermark": {"date": last_watermark["date"], "last_id": last_watermark["last_id"]}
                }, default=str),
                "has_new_data": False,
                "process": process,
            }

        result= con.run(
            "SELECT * FROM aws_s3.query_export_to_s3("
            "'SELECT * FROM temp_batch ORDER BY last_updated, id', "
            "aws_commons.create_s3_uri(:bucket, :file_path, :region), "
            "options := 'FORMAT CSV, HEADER true')",
            bucket=BUCKET_NAME, file_path=s3_key_process, region=REGION,
        )
        rows_uploaded, files_uploaded, bytes_uploaded = result[0]
        watermark = con.run("SELECT last_updated, id FROM temp_batch ORDER BY last_updated DESC, id DESC LIMIT 1;")
        new_last_ts, new_last_id = watermark[0]
        new_last_ts = new_last_ts.isoformat()
        con.run("COMMIT")

        if rows_uploaded > 0:
            append_watermark(process, new_last_ts, new_last_id, s3_key_process, rows_uploaded)
            return {
                "statusCode": 200,
                "body": json.dumps({
                    "message": f"{process} Data exported to S3 successfully.",
                    "s3_key": s3_key_process,
                    "new_watermark": {"date": new_last_ts, "last_id": new_last_id}
                }, default=str),
                "has_new_data": True,
                "process": process,
            }
        else:
            # Guards against an implicit `None` return, which would leave
            # Step Functions' Choice state with no `has_new_data` field to
            # branch on.
            return {
                "statusCode": 200,
                "body": json.dumps({"message": f"No rows uploaded for {process}."}, default=str),
                "has_new_data": False,
                "process": process,
            }

    except Exception:
        con.run("ROLLBACK")
        raise
