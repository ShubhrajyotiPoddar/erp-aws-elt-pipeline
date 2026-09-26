import sys
import traceback

import boto3
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from pyspark.context import SparkContext
from pyspark.sql.functions import col, to_timestamp, date_format, row_number
from pyspark.sql.window import Window

args = getResolvedOptions(
    sys.argv,
    [
        "JOB_NAME",
        "source_bucket",     # shubhra-demo-s3-v001
        "source_domain",     # GRN, PUR, ISSUE
        "target_database",   # erp_silver
        "target_table",      # GRN, PUR, ISSUE
        "sns_topic_arn",     # arn:aws:sns:ap-south-1:<ACCOUNT_ID>:bronze-silver-error
    ],
)

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

sns = boto3.client("sns")


def run():
    source_path = f"s3://{args['source_bucket']}/elt_rds_dumps/{args['source_domain']}/"

    # transformation_ctx is the key Glue uses to persist bookmark state for
    # this specific source — keep it stable across runs. Bookmarks only work
    # with this GlueContext reader, not a plain spark.read.csv().
    dynamic_frame = glueContext.create_dynamic_frame.from_options(
        connection_type="s3",
        connection_options={"paths": [source_path], "recurse": True},
        format="csv",
        format_options={"withHeader": True},
        transformation_ctx=f"bronze_{args['source_domain']}_source",
    )

    df = dynamic_frame.toDF()

    if df.rdd.isEmpty():
        print("No new files since the last bookmark — nothing to process.")
        return

    df = df.withColumn("last_updated", to_timestamp(col("last_updated")))
    df = df.withColumn("year", date_format(col("last_updated"), "yyyy"))
    df = df.withColumn("month", date_format(col("last_updated"), "MM"))

    # keep only the latest version of each id within this batch
    window = Window.partitionBy("id").orderBy(col("last_updated").desc())
    df = df.withColumn("rn", row_number().over(window)).filter(col("rn") == 1).drop("rn")

    final_frame = DynamicFrame.fromDF(df, glueContext, "final_frame")

    silver_path = f"s3://{args['source_bucket']}/silver/{args['target_table']}/"

    sink = glueContext.getSink(
        connection_type="s3",
        path=silver_path,
        enableUpdateCatalog=True,
        updateBehavior="UPDATE_IN_DATABASE",
        partitionKeys=["year", "month"],
        transformation_ctx=f"silver_{args['source_domain']}_sink",
    )
    sink.setFormat("glueparquet")
    sink.setCatalogInfo(catalogDatabase=args["target_database"], catalogTableName=args["target_table"])
    sink.writeFrame(final_frame)

    print(f"Wrote {df.count()} rows to {silver_path}")


try:
    run()
    job.commit()
except Exception:
    error_message = traceback.format_exc()
    print(error_message)
    # sns.publish(
    #     TopicArn=args["sns_topic_arn"],
    #     Subject=f"Glue transform failed: {args['target_table']}",
    #     Message=error_message,
    # )
    raise
