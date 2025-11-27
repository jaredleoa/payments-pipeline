# handler.py

import os
import json
import uuid
import random
from datetime import datetime, timezone
from decimal import Decimal

import boto3

TABLE_NAME = os.environ.get("TABLE_NAME")

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)


def _generate_mock_payment_event():
    now = datetime.now(timezone.utc).isoformat()

    return {
        "payment_id": str(uuid.uuid4()),
        "created_at": now,
        "amount": Decimal(str(round(random.uniform(1.0, 500.0), 2))),
        "currency": random.choice(["EUR", "GBP", "USD"]),
        "merchant_id": random.choice(
            ["MRC-CAFE-001", "MRC-GROCERY-042", "MRC-ONLINE-999"]
        ),
        "status": random.choice(["AUTHORIZED", "CAPTURED", "DECLINED"]),
        "source": random.choice(["CARD", "WALLET", "BANK_TRANSFER"]),
    }


def lambda_handler(event, context):
    count = 1
    if isinstance(event, dict):
        raw_count = event.get("count")
        if isinstance(raw_count, int) and raw_count > 0:
            count = raw_count

    inserted = []

    for _ in range(count):
        item = _generate_mock_payment_event()
        table.put_item(Item=item)
        inserted.append(item["payment_id"])

    body = {
        "message": "Mock payment events inserted.",
        "table": TABLE_NAME,
        "count": len(inserted),
        "payment_ids": inserted,
    }

    return {"statusCode": 200, "body": json.dumps(body)}
