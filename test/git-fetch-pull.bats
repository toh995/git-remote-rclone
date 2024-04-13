# vi: filetype=sh
readonly ROOT_DIR=$(pwd)
declare RESTIC_SOURCE_DIR
declare LOCAL_DIR

fetch_local() {
	GIT_DIR=$LOCAL_DIR git fetch
}

pull_local() {
	GIT_DIR=$LOCAL_DIR git pull
}

setup() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'

	# Override $PATH to use the current repo's executable
	DIR=$(dirname $BATS_TEST_FILENAME)
	PATH="$DIR/../:$PATH"

	# set up stuff
	RESTIC_SOURCE_DIR="${BATS_TEST_TMPDIR}/$(uuidgen)/.git"
	LOCAL_DIR="${BATS_TEST_TMPDIR}/$(uuidgen)/.git"

	# set up $RESTIC_SOURCE_DIR with an initial commit
	mkdir -p $RESTIC_SOURCE_DIR
	GIT_DIR=$RESTIC_SOURCE_DIR git init
	GIT_DIR=$RESTIC_SOURCE_DIR git commit --allow-empty -m "first commit"
	cd $RESTIC_SOURCE_DIR && restic backup . && cd $ROOT_DIR

	# clone repo to $LOCAL_DIR
	mkdir -p $LOCAL_DIR
	GIT_DIR=$LOCAL_DIR git init
	GIT_DIR=$LOCAL_DIR git remote add origin "restic::/${RESTIC_REPOSITORY}"
	GIT_DIR=$LOCAL_DIR git fetch
	GIT_DIR=$LOCAL_DIR git checkout master

	# ensure the clone was successful
	assert_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$(GIT_DIR=$RESTIC_SOURCE_DIR git rev-parse HEAD)
}

@test "local and remote on same commit" {
	local -r commit_sha=$(GIT_DIR=$RESTIC_SOURCE_DIR git rev-parse HEAD)
	fetch_local
	pull_local
	assert_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$commit_sha
	assert_equal $(GIT_DIR=$RESTIC_SOURCE_DIR git rev-parse HEAD) \
		$commit_sha
}

@test "remote ahead of local by 1 commit" {
	# add a commit to remote
	GIT_DIR=$RESTIC_SOURCE_DIR git commit --allow-empty -m "commit"
	cd $RESTIC_SOURCE_DIR && restic backup . && cd $ROOT_DIR
	assert_not_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$(GIT_DIR=$RESTIC_SOURCE_DIR git rev-parse HEAD)

	# fetch + pull
	local -r remote_commit_sha=$(GIT_DIR=$RESTIC_SOURCE_DIR git rev-parse HEAD)
	run fetch_local
	assert_failure
	pull_local
	assert_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$remote_commit_sha
}

@test "remote ahead of local by 1 commit, with locally unstaged files" {
	local -r FILENAME="foo.txt"

	# add a commit to remote, with a new file
	cd "${RESTIC_SOURCE_DIR}/../"
	uuidgen >$FILENAME
	git add .
	git commit -m "new file"
	cd $RESTIC_SOURCE_DIR && restic backup . && cd $ROOT_DIR
	assert_not_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$(GIT_DIR=$RESTIC_SOURCE_DIR git rev-parse HEAD)

	# create a locally unstaged file
	uuidgen >"${LOCAL_DIR}/../${FILENAME}"

	# fetch + pull
	local -r remote_commit_sha=$(GIT_DIR=$RESTIC_SOURCE_DIR git rev-parse HEAD)
	run fetch_local
	assert_failure
	run pull_local
	assert_failure
	assert_not_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$remote_commit_sha
}

@test "local ahead of remote by 1 commit" {
	# add a commit to local
	GIT_DIR=$LOCAL_DIR git commit --allow-empty -m "commit"
	assert_not_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$(GIT_DIR=$RESTIC_SOURCE_DIR git rev-parse HEAD)

	# fetch + pull
	local -r local_commit_sha=$(GIT_DIR=$LOCAL_DIR git rev-parse HEAD)
	fetch_local
	pull_local
	assert_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$local_commit_sha
}

@test "local and remote divergent commits" {
	# add a commit to remote
	GIT_DIR=$RESTIC_SOURCE_DIR git commit --allow-empty -m "commit"
	cd $RESTIC_SOURCE_DIR && restic backup . && cd $ROOT_DIR
	assert_not_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$(GIT_DIR=$RESTIC_SOURCE_DIR git rev-parse HEAD)

	# add a commit to local
	GIT_DIR=$LOCAL_DIR git commit --allow-empty -m "ogres are like onions"
	assert_not_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$(GIT_DIR=$RESTIC_SOURCE_DIR git rev-parse HEAD)

	# fetch + pull
	run fetch_local
	assert_failure
	run pull_local
	assert_failure
	assert_not_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$(GIT_DIR=$RESTIC_SOURCE_DIR git rev-parse HEAD)
}
