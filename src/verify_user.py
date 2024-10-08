import boto3
from os import getenv
from urllib.parse import parse_qsl


def lambda_handler(event, context):
    s3_client = boto3.client("s3")
    try:
        # rawQueryString contains the raw query string from the HTTP request.
        # "queryStringParameters": {
        #     "param1": "value1",
        #     "param2": "value2"
        #   }
        print("queryStringParameters for verify user handler: ", event["queryStringParameters"])
        query_string = event["queryStringParameters"]
        item_found = is_key_in_db(db_key=query_string)
        result_file = "index.html" if item_found else "error.html"
        print("S3 verify user result file: ", result_file)
        response = s3_client.get_object(Bucket=getenv("WEBSITE_S3"), Key=result_file)
        print("S3 response for verify user result file: ", response)
        html_body = response["Body"].read().decode("utf-8")
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "text/html"},
            "body": html_body,
        }
    except Exception as error_details:
        print(error_details)
        return "Error verifying user. Check Logs for more details."


def is_key_in_db(db_key):
    print(f"Checking if key: {db_key} exists in the dynamodb table")
    db_client = boto3.resource("dynamodb")
    db_table = db_client.Table(getenv("DB_TABLE_NAME"))
    try:
        response = db_table.get_item(Key=db_key)
        print(f"Dynamodb response when get item {db_key}: {response}")
        item = response.get("Item")
        if item:
            print(f"Item with key: {db_key} found")
            return True
        else:
            print(f"Item with key: {db_key} not found")
            return False
    except Exception as err:
        print(f"Error Getting Item: {err}")
        return False
