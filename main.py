import subprocess
import time
import os
while True:
    subprocess.call(["id"])
    # pid = os.getpid()
    # subprocess.call(["echo", "%d"%pid])
    subprocess.call(["date"])
    time.sleep(4)