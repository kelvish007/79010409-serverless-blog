"""GET /posts - public. Returns all blog posts, newest first."""
import json
import os

import boto3

table = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])

HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
}


def handler(event, context):
    print("listPosts invoked")
    try:
        items = []
        resp = table.scan()
        items.extend(resp.get("Items", []))
        # scan returns max 1 MB per call, so keep going until no more pages
        while "LastEvaluatedKey" in resp:
            resp = table.scan(ExclusiveStartKey=resp["LastEvaluatedKey"])
            items.extend(resp.get("Items", []))

        items.sort(key=lambda p: p.get("createdAt", ""), reverse=True)
        return {"statusCode": 200, "headers": HEADERS, "body": json.dumps(items, default=str)}
    except Exception as exc:  # errors go to CloudWatch logs
        print("ERROR listPosts:", repr(exc))
        return {"statusCode": 500, "headers": HEADERS, "body": json.dumps({"error": "Internal error"})}
