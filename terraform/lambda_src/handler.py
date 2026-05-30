import json

from profiling import maybe_pyspy


def _fib(n):
    if n <= 1:
        return n
    return _fib(n - 1) + _fib(n - 2)


def _bubble_sort(arr):
    n = len(arr)
    for i in range(n):
        for j in range(n - i - 1):
            if arr[j] > arr[j + 1]:
                arr[j], arr[j + 1] = arr[j + 1], arr[j]
    return arr


def _slow_computation():
    # ~29M recursive calls — gives deep, recognisable stacks in py-spy samples
    fib_result = _fib(35) # 35
    # ~4.5M comparisons in a tight O(n²) loop — samples cluster in inner loop
    sorted_result = _bubble_sort(list(range(3000, 0, -1)))  # 3000
    return fib_result, sorted_result[-1]


def handler(event, context):
    with maybe_pyspy(context):
        fib, sort_max = _slow_computation()

    return {
        "statusCode": 200,
        "body": json.dumps({"message": "success", "fib_35": fib, "sort_max": sort_max}),
    }