from collections.abc import Mapping
import os
import subprocess


def run_cmd(cmd: list[str], env_vars: Mapping[str, str] = {}, input: str = "") -> str:
    res = subprocess.run(
        cmd, env={**os.environ, **env_vars}, capture_output=True, text=True, input=input
    )
    # raise an exception for non-zero exit code
    res.check_returncode()
    return res.stdout
