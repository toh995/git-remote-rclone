# git-remote-restic
> [!WARNING]
> This project is in development and NOT usable.

Inspired by [CGamesPlay/git-remote-restic](https://github.com/CGamesPlay/git-remote-restic), however, doesn't require a custom restic fork.

Creates a [git remote helper](https://git-scm.com/docs/gitremote-helpers)

Other projects:
- https://keybase.io/blog/encrypted-git-for-everyone
- https://github.com/spwhitton/git-remote-gcrypt
- https://github.com/GenerousLabs/git-remote-encrypted
- https://github.com/nathants/git-remote-aws

## Installation
TODO

## Setup
### Configure rclone on your machine
- Use the [rclone docs](https://rclone.org/crypt/) 
- Set up an _encrypted_ remote

### FIRST TIME ONLY: Create a bare git repo locally, then sync to rclone
```bash
BARE_DIR=/tmp/repo-bare
REPO_DIR=/tmp/repo
mkdir -p $BARE_DIR && cd $BARE_DIR
git init --bare
rm ./hooks/* # hooks not needed

git clone $BARE_DIR $REPO_DIR
cd $REPO_DIR
git commit --allow-empty -m "first commit"
git branch -m master main
git push -u origin main

cd $BARE_DIR
git symbolic-ref HEAD refs/heads/main # change HEAD to the main branch
rclone sync $BARE_DIR rclone-remote:path/to/use
```

### Clone the repo to a new machine
NOTE: `git clone` does NOT work! Use this instead:
```bash
mkdir ./cloned && cd ./cloned
git init
git remote add origin "rclone::rclone-remote:path/to/use"
git fetch
git checkout main
```

### Set up kopia for backups
- If setting up for the first time, use [kopia repository create](https://kopia.io/docs/getting-started/#creating-a-repository)
- Otherwise, use [kopia repository connect](https://kopia.io/docs/getting-started/#connecting-to-repository)

## Usage
Use `git fetch` and `git push` as normal.

**KNOWN LIMITATIONS:**
- `git fetch` sometimes shows an error, even though the fetch was successful
- The first `git pull` won't work
    - Instead, you can do `git fetch` and then `git pull` (or `git pull` twice)

## Tests
We use the [bats](https://github.com/bats-core/bats-core) test framework.

First, install the `bats` binary to `PATH`. Then do:
```bash
bats ./test
```
