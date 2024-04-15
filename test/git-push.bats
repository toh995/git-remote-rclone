# vi: filetype=sh
readonly ROOT_DIR="$(pwd)"
declare RCLONE_SOURCE
declare RCLONE_BARE
declare LOCAL_DIR

push_local() {
	GIT_DIR=$LOCAL_DIR git push
}

setup() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'

	# set up stuff
	RCLONE_BARE="${BATS_TEST_TMPDIR}/$(uuidgen)"
	RCLONE_SOURCE="${BATS_TEST_TMPDIR}/$(uuidgen)/.git"
	LOCAL_DIR="${BATS_TEST_TMPDIR}/$(uuidgen)/.git"

	# set up rclone with an initial commit
	mkdir -p $RCLONE_BARE
	GIT_DIR=$RCLONE_BARE git init --bare

	git clone $RCLONE_BARE "$(dirname $RCLONE_SOURCE)"
	GIT_DIR=$RCLONE_SOURCE git commit --allow-empty -m "first commit"
	GIT_DIR=$RCLONE_SOURCE git push
	rclone sync $RCLONE_BARE $RCLONE_REMOTE

	# clone repo to $LOCAL_DIR
	mkdir -p $LOCAL_DIR
	GIT_DIR=$LOCAL_DIR git init
	GIT_DIR=$LOCAL_DIR git remote add origin "rclone::${RCLONE_REMOTE}"
	GIT_DIR=$LOCAL_DIR git fetch
	GIT_DIR=$LOCAL_DIR git checkout master

	# ensure the clone was successful
	assert_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$(GIT_DIR=$RCLONE_SOURCE git rev-parse HEAD)
}

@test "local and remote on same commit" {
	local -r commit_sha=$(GIT_DIR=$RCLONE_SOURCE git rev-parse HEAD)
	push_local
	assert_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$commit_sha
	assert_equal $(GIT_DIR=$RCLONE_SOURCE git rev-parse HEAD) \
		$commit_sha
}

@test "remote ahead of local by 1 commit" {
	# add a commit to remote
	GIT_DIR=$RCLONE_SOURCE git commit --allow-empty -m "commit"
	GIT_DIR=$RCLONE_SOURCE git push
	rclone sync $RCLONE_BARE $RCLONE_REMOTE
	assert_not_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$(GIT_DIR=$RCLONE_SOURCE git rev-parse HEAD)

	# push
	run push_local
	assert_output --partial "error: failed to push some refs"
	assert_not_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$(GIT_DIR=$RCLONE_SOURCE git rev-parse HEAD)
}

@test "local ahead of remote by 1 commit" {
	# add a commit to local
	GIT_DIR=$LOCAL_DIR git commit --allow-empty -m "commit"
	assert_not_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$(GIT_DIR=$RCLONE_SOURCE git rev-parse HEAD)

	# push
	local -r local_commit_sha=$(GIT_DIR=$LOCAL_DIR git rev-parse HEAD)
	push_local
	rclone sync $RCLONE_REMOTE $RCLONE_BARE
	assert_equal $(GIT_DIR=$RCLONE_BARE git rev-parse HEAD) \
		$local_commit_sha
}

@test "local and remote divergent commits" {
	# add a commit to remote
	GIT_DIR=$RCLONE_SOURCE git commit --allow-empty -m "commit"
	GIT_DIR=$RCLONE_SOURCE git push
	rclone sync $RCLONE_BARE $RCLONE_REMOTE
	assert_not_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$(GIT_DIR=$RCLONE_SOURCE git rev-parse HEAD)

	# add a commit to local
	GIT_DIR=$LOCAL_DIR git commit --allow-empty -m "ogres are like onions"
	assert_not_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$(GIT_DIR=$RCLONE_SOURCE git rev-parse HEAD)

	# push
	run push_local
	assert_output --partial "error: failed to push some refs"
	assert_not_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$(GIT_DIR=$RCLONE_SOURCE git rev-parse HEAD)
}

@test "pushing a net-new branch from local to remote" {
	# add a new local branch
	local -r new_branch=$(uuidgen)
	GIT_DIR=$LOCAL_DIR git checkout -b $new_branch

	# ensure the branch doesn't exist on remote yet
	check_branch() {
		GIT_DIR=$RCLONE_BARE git rev-parse --verify $new_branch
	}
	run check_branch
	assert_failure

	# push
	GIT_DIR=$LOCAL_DIR git push origin $new_branch

	# ensure the branch exists on the remote now
	rclone sync $RCLONE_REMOTE $RCLONE_BARE
	run check_branch
	assert_success
}

@test "pushing a branch deletion from local to remote" {
	# add a branch to the remote
	local -r del_branch="$(uuidgen)"
	GIT_DIR=$RCLONE_SOURCE git checkout -b $del_branch
	GIT_DIR=$RCLONE_SOURCE git push -u origin $del_branch
	rclone sync $RCLONE_BARE $RCLONE_REMOTE

	# delete the branch
	GIT_DIR=$LOCAL_DIR git fetch
	GIT_DIR=$LOCAL_DIR git push -d origin $del_branch

	# ensure the branch is deleted on the remote
	rclone sync $RCLONE_REMOTE $RCLONE_BARE
	check_branch() {
		GIT_DIR=$RCLONE_BARE git rev-parse --verify $del_branch
	}
	run check_branch
	assert_failure
}

@test "push sends a backup to kopia" {
	# add a commit to local
	GIT_DIR=$LOCAL_DIR git commit --allow-empty -m "commit"
	assert_not_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$(GIT_DIR=$RCLONE_SOURCE git rev-parse HEAD)

	local -r prev_snapshots="$(kopia snapshot list --json)"

	# push
	local -r local_commit_sha=$(GIT_DIR=$LOCAL_DIR git rev-parse HEAD)
	push_local

	# ensure that a new snapshot was saved
	local -r curr_snapshots="$(kopia snapshot list --json)"
	assert_equal "$(echo "${curr_snapshots}" | jq length)" \
		"$((1 + "$(echo "${prev_snapshots}" | jq length)"))"

	local -r curr_latest_id="$(echo "${curr_snapshots}" | jq --raw-output "sort_by(.endTime) | .[-1].id")"
	local -r prev_latest_id="$(echo "${prev_snapshots}" | jq --raw-output "sort_by(.endTime) | .[-1].id")"
	assert_not_equal "${curr_latest_id}" "${prev_latest_id}"

	# inspect the snapshot contents
	local -r kopia_restore_dir="${BATS_TEST_TMPDIR}/$(uuidgen)"
	kopia restore "${curr_latest_id}" "${kopia_restore_dir}"
	rclone sync $RCLONE_REMOTE $RCLONE_BARE

	readonly prev_opt="$(shopt -p | grep globstar)"
	shopt -s globstar
	local -ra kopia_files=(${kopia_restore_dir}/**)
	local -ra rclone_files=(${RCLONE_BARE}/**)
	eval "${prev_opt}"

	assert_equal "${#kopia_files[@]}" "${#rclone_files[@]}"

	for i in "${!kopia_files[@]}"; do
		local kopia_filename="${kopia_files[$i]}"
		local rclone_filename="${rclone_files[$i]}"
		assert_equal "${kopia_filename##${kopia_restore_dir}}" \
			"${rclone_filename##${RCLONE_BARE}}"
		if [[ -f "${kopia_filename}" ]]; then
			local kopia_hash="$(md5sum "${kopia_filename}")"
			local rclone_hash="$(md5sum "${rclone_filename}")"
			assert_equal "${kopia_hash%% *}" "${rclone_hash%% *}"
		fi
	done
}
