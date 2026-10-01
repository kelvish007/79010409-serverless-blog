"""GET /posts/{id} - public. Returns a single blog post."""
import json
import os

import boto3

table = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])

HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
}


def handler(event, context):
    post_id = (event.get("pathParameters") or {}).get("id")
    print("getPost invoked for id:", post_id)

    if not post_id:
        return {"statusCode": 400, "headers": HEADERS, "body": json.dumps({"error": "Missing post id"})}

    try:
        item = table.get_item(Key={"postId": post_id}).get("Item")
        if not item:
            return {"statusCode": 404, "headers": HEADERS, "body": json.dumps({"error": "Post not found"})}
        return {"statusCode": 200, "headers": HEADERS, "body": json.dumps(item, default=str)}
    except Exception as exc:  # errors go to CloudWatch logs
        print("ERROR getPost:", repr(exc))
        return {"statusCode": 500, "headers": HEADERS, "body": json.dumps({"error": "Internal error"})}
