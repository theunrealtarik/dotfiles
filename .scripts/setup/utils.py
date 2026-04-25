import subprocess
import sys

RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
NC = "\033[0m"


def log(msg: str):
    print(f"{GREEN}[LOG]{NC} {msg}")


def warn(msg: str):
    print(f"{YELLOW}[WARN]{NC} {msg}")


def error(msg: str, exit: bool = True):
    print(f"{RED}[ERROR]{NC} {msg}")
    sys.exit(int(exit))


def run(cmd, check=True):
    result = subprocess.run(cmd, shell=True)
    if check and result.returncode != 0:
        error(f"Command failed: {cmd}")
    return result.returncode
