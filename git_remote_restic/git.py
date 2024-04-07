from enum import Enum, unique
from pathlib import Path

from .run_cmd import run_cmd


@unique
class ObjectType(Enum):
    BLOB = "blob"
    COMMIT = "commit"
    TAG = "tag"
    TREE = "tree"


def copy_object(sha: str, from_dir: Path, to_dir: Path):
    obj_type = run_cmd(["git", "cat-file", "-t", sha])
    file_contents = run_cmd(["git", "cat-file", obj_type, sha])
    run_cmd(["git", "hash-object", "-w", "--stdin", "-t", obj_type])

    # copy all children
    match obj_type:
        case "tag":
            pass
        case "blob":
            pass
        case "tree":
            pass


def get_obj_type(sha: str) -> ObjectType:
    obj_type: str = run_cmd(["git", "cat-file", "-t", sha])
    return ObjectType(obj_type)
