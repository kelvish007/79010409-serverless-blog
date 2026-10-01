"""POST /posts - protected by the Cognito authorizer. Creates a blog post."""
import json
import os
import uuid
from datetime import datetime, timezone

import boto3

table = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])

HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
}


def handler(event, context):
    print("createPost invoked")
    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return {"statusCode": 400, "headers": HEADERS, "body": json.dumps({"error": "Invalid JSON"})}

    title = str(body.get("title", "")).strip()
    content = str(body.get("content", "")).strip()
    if not title or not content:
        return {"statusCode": 400, "headers": HEADERS, "body": json.dumps({"error": "Title and content are required"})}

    # Cognito claims are added to the request by the API Gateway authorizer
    claims = (event.get("requestContext", {}).get("authorizer") or {}).get("claims", {})
    author = claims.get("email", "unknown")

    post = {
        "postId": str(uuid.uuid4()),
        "title": title[:200],
        "content": content[:5000],
        "author": author,
        "createdAt": datetime.now(timezone.utc).isoformat(),
    }

    try:
        table.put_item(Item=post)
        return {"statusCode": 201, "headers": HEADERS, "body": json.dumps(post)}
    except Exception as exc:  # errors go to CloudWatch logs
        print("ERROR createPost:", repr(exc))
        return {"statusCode": 500, "headers": HEADERS, "body": json.dumps({"error": "Internal error"})}
