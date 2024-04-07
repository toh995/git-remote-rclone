import pathlib
import subprocess

# from typing import Self


class Repo:
    def __init__(self, path: pathlib.Path, password: str) -> None:
        self.path = path
        self.password = password

    @property
    def __default_cmd_args(self) -> list[str]:
        return [
            "--repo",
            str(self.path),
            "--password-command",
            f"echo '{self.password}'",
        ]

    def init(self) -> None:
        cmd = ["restic", "init"] + self.__default_cmd_args
        subprocess.run(cmd, check=True)

    def restore(self, target) -> None:
        cmd = ["restic", "restore", "--target", target] + self.__default_cmd_args + [""]
        subprocess.run(cmd, check=True)

    # @staticmethod
    # def init(repo_path: pathlib.Path, password: str) -> Repo:
    #     return Repo(repo_path, password)


# def init()


def restore(target):
    cmd = ["restic", "restore", "latest", "--target", target]
    subprocess.run(cmd, check=True)
