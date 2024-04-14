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

## Usage
### Configuration
Set up password in:
- `$XDG_CONFIG_HOME/git-remote-restic/restic-password`

Optional - if using aws:
- `$XDG_CONFIG_HOME/git-remote-restic/aws-access-key-id`
- `$XDG_CONFIG_HOME/git-remote-restic/aws-secret-access-key`

### Initial restic set up
```bash
# Set up a restic repo
# NOTE: On first init, both the `host` and `username`
# are stored in PLAINTEXT on the restic repo/server. 
# To obfuscate, might want to change the host/username,
# and/or run from a VM
export AWS_ACCESS_KEY_ID=foo
export AWS_SECRET_ACCESS_KEY=bar
export RESTIC_RESPOSITORY=s3:s3.amazonaws.com/my.bucket.name/path/to/repository
export RESTIC_PASSWORD=baz
restic init

# Create a git repo, to store inside the restic repo
mkdir ./repo && cd ./repo
git init
git commit --allow-empty -m "first commit"
git branch -m master main
cd ..
git clone --bare ./repo ./repo-bare
cd ./repo-bare
# don't need the git hooks
rm ./hooks/* 
# save the git repo to restic
restic backup .
```

### Cloning from restic to a new machine
```bash
RESTIC_RESPOSITORY=s3:s3.amazonaws.com/my.bucket.name/path/to/repository
mkdir -p ./cloned && cd ./cloned
git init
git remote add origin "restic::${RESTIC_REPOSITORY}"
git fetch
git checkout main
```

## Testing
To run the entire test suite:
```bash
bats ./test
```

Need to have the [bats](https://github.com/bats-core/bats-core) binary installed in `PATH`
