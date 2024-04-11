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
- Set up a restic repository, per the [instructions](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html)
- Set the following env vars:
    - `RESTIC_REPOSITORY`
    - `RESTIC_PASSWORD` or `RESTIC_PASSWORD_FILE`

```bash
git remote add origin restic::$RESTIC_REPOSITORY
```

Use `git fetch` and `git push` as normal
