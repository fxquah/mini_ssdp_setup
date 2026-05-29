# profiling.py — shared across all lambdas in repo 2
import contextlib
import os
import subprocess
import tempfile

import boto3


@contextlib.contextmanager
def maybe_pyspy(context):
    if os.environ.get("ENABLE_PYSPY") != "1":
        yield
        return

    fd, output = tempfile.mkstemp(suffix=".json")
    os.close(fd)
    spy = subprocess.Popen([
        "/opt/bin/py-spy", "record",
        "--pid", str(os.getpid()),
        "--output", output,
        "--format", "speedscope",
        "--nonblocking",
    ])
    try:
        yield
    finally:
        spy.terminate()
        spy.wait()
        with open(output, "rb") as f:
            boto3.client("s3").put_object(
                Bucket=os.environ["PYSPY_S3_BUCKET"],
                Key=f"profiles/{context.function_name}/{context.aws_request_id}.json",
                Body=f.read(),
            )