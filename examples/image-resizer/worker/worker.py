"""Background worker: pops resize jobs from Redis and writes thumbnails."""
import json
import os
import time

import psycopg
import redis
from PIL import Image

DATABASE_URL = os.environ["DATABASE_URL"]
REDIS_URL = os.environ.get("REDIS_URL", "redis://localhost:6379/0")
OUTPUT_DIR = os.environ.get("OUTPUT_DIR", "/data/outputs")

SIZES = [(128, 128), (512, 512)]
MAX_ATTEMPTS = 3


def resize(job):
    outputs = []
    with Image.open(job["path"]) as img:
        for width, height in SIZES:
            copy = img.copy()
            copy.thumbnail((width, height))
            out = os.path.join(OUTPUT_DIR, f"{job['job_id']}_{width}x{height}.png")
            copy.save(out, "PNG")
            outputs.append(out)
    return outputs


def main():
    queue = redis.Redis.from_url(REDIS_URL)
    while True:
        _, raw = queue.brpop("resize:jobs")
        job = json.loads(raw)
        attempts = 0
        while True:
            try:
                outputs = resize(job)
                status = "done"
                break
            except OSError:
                attempts += 1
                if attempts >= MAX_ATTEMPTS:
                    outputs, status = [], "failed"
                    break
                # Back off because the shared volume is sometimes slow to show new files.
                time.sleep(2 ** attempts)
        with psycopg.connect(DATABASE_URL) as conn:
            conn.execute(
                "UPDATE jobs SET status = %s, outputs = %s WHERE id = %s",
                (status, json.dumps(outputs), job["job_id"]),
            )


if __name__ == "__main__":
    main()
