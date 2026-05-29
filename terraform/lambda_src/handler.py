import json

from profiling import maybe_pyspy


def _slow_computation():
    total = 0
    for i in range(5_000_000):
        total += i * i
    return total


def handler(event, context):
    with maybe_pyspy(context):
        result = _slow_computation()

    return {
        "statusCode": 200,
        "body": json.dumps({"message": "success", "result": result}),
    }