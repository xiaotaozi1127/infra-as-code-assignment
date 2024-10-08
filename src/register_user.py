from os import getenv

import boto3


def lambda_handler(event, context):
    # "queryStringParameters":
    #     {
    #         "userid": "taohui"
    #     }
    print("queryStringParameters for register user: ", event["queryStringParameters"])
    query_string = event["queryStringParameters"]
    client = boto3.resource("dynamodb")
    db_table = client.Table(getenv("DB_TABLE_NAME"))
    try:
        # Define the item you want to put into the table
        # item = {
        #     'YourPrimaryKey': 'YourPrimaryKeyValue',  # Replace with your primary key and value
        #     'Attribute1': 'Value1',
        #     'Attribute2': 'Value2',
        #     # Add more attributes as needed
        # }
        db_table.put_item(Item=query_string)
        print(f"Register user: {query_string} successfully")
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": "{\"message\":\"Registered User Successfully\"}",
            "isBase64Encoded": False
        }
    except Exception as error_details:
        print(error_details)
        return {"message": "Error registering user. Check Logs for more details."}
