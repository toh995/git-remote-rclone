import os
import pytest
from subprocess import CalledProcessError
from uuid import uuid4

from .run_cmd import run_cmd


def test_output():
    out = run_cmd(["echo", "foo"])
    assert out == "foo\n"


def test_input():
    input = "foo"
    output = run_cmd(["cat"], input=input)
    assert output == input


def test_failure():
    with pytest.raises(CalledProcessError) as excinfo:
        run_cmd(["false"])
    assert excinfo.type == CalledProcessError


def test_env_var():
    var_name = str(uuid4())
    og_val = os.environ.get(var_name, "")

    val1 = "1"
    val2 = "2"

    # global env var should be respected
    os.environ[var_name] = val1
    out = run_cmd(["printenv"])
    lines = out.split("\n")
    line = next(line for line in lines if var_name in line)
    assert line == f"{var_name}={val1}"

    # with custom env var
    out = run_cmd(["printenv"], {var_name: val2})
    lines = out.split("\n")
    line = next(line for line in lines if var_name in line)
    assert line == f"{var_name}={val2}"

    # custom env var shouldn't affect the global env var
    out = run_cmd(["printenv"])
    lines = out.split("\n")
    line = next(line for line in lines if var_name in line)
    assert line == f"{var_name}={val1}"

    # reset state
    os.environ[var_name] = og_val
