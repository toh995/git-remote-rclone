from pathlib import Path
from uuid import uuid4

import git
import pytest

import git_remote_restic.restic as restic


@pytest.fixture
def restic_repo(tmp_path: Path) -> restic.Repo:
    repo_path = tmp_path / str(uuid4())
    password = str(uuid4())
    repo = restic.Repo(repo_path, password)
    repo.init()
    return repo


@pytest.fixture
def local_remote_repo(tmp_path: Path) -> git.Repo:
    repo_path = tmp_path / str(uuid4())
    return git.Repo.init(repo_path, bare=True)


def test_foo(local_remote_repo, restic_repo):
    pass


def test_bar(local_remote_repo, restic_repo):
    pass
