# profiling.py — shared across all lambdas in repo 2
import contextlib
import os
import signal
import subprocess
import tempfile

import boto3


@contextlib.contextmanager
def maybe_pyspy(context):
    if os.environ.get("ENABLE_PYSPY") != "1":
        yield
        return

    fd, output = tempfile.mkstemp(suffix=".prof")
    os.close(fd)
    cmd = [
        "/opt/bin/py-spy", "record",
        "--pid", str(os.getpid()),
        "--output", output,
        "--format", "speedscope",
        "--nonblocking",
    ]
    print(f"[pyspy] {' '.join(cmd)}")
    spy = subprocess.Popen(cmd, stderr=subprocess.PIPE)
    try:
        yield
    finally:
        spy.send_signal(signal.SIGINT)
        _, stderr = spy.communicate(timeout=10)
        if stderr:
            print(f"[pyspy] stderr: {stderr.decode()}")
        with open(output, "rb") as f:
            boto3.client("s3").put_object(
                Bucket=os.environ["PYSPY_S3_BUCKET"],
                Key=f"profiles/{context.function_name}/{context.aws_request_id}.prof",
                Body=f.read(),
            )