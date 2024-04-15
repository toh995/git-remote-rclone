# vi: filetype=sh
readonly ROOT_DIR="$(pwd)"
declare RCLONE_BARE
declare RCLONE_SOURCE
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
	fetch_local
	pull_local
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

	# fetch + pull
	local -r remote_commit_sha=$(GIT_DIR=$RCLONE_SOURCE git rev-parse HEAD)
	run fetch_local
	assert_failure
	pull_local
	assert_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$remote_commit_sha
}

@test "remote ahead of local by 1 commit, with locally unstaged files" {
	local -r FILENAME="foo.txt"

	# add a commit to remote, with a new file
	uuidgen >"$(dirname $RCLONE_SOURCE)/${FILENAME}"
	cd "$(dirname $RCLONE_SOURCE)"
	GIT_DIR=$RCLONE_SOURCE git add "$(dirname $RCLONE_SOURCE)/${FILENAME}"
	GIT_DIR=$RCLONE_SOURCE git commit -m "new file"
	GIT_DIR=$RCLONE_SOURCE git push
	rclone sync $RCLONE_BARE $RCLONE_REMOTE
	assert_not_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$(GIT_DIR=$RCLONE_SOURCE git rev-parse HEAD)

	# create a locally unstaged file
	uuidgen >"$(dirname $LOCAL_DIR)/${FILENAME}"

	# fetch + pull
	local -r remote_commit_sha=$(GIT_DIR=$RCLONE_SOURCE git rev-parse HEAD)
	cd "${LOCAL_DIR}/../"
	run fetch_local
	assert_failure
	run pull_local
	assert_failure
	assert_not_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$remote_commit_sha
	cd $ROOT_DIR
}

@test "local ahead of remote by 1 commit" {
	# add a commit to local
	GIT_DIR=$LOCAL_DIR git commit --allow-empty -m "commit"
	assert_not_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$(GIT_DIR=$RCLONE_SOURCE git rev-parse HEAD)

	# fetch + pull
	local -r local_commit_sha=$(GIT_DIR=$LOCAL_DIR git rev-parse HEAD)
	fetch_local
	pull_local
	assert_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
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

	# fetch + pull
	run fetch_local
	assert_failure
	run pull_local
	assert_failure
	assert_not_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$(GIT_DIR=$RCLONE_SOURCE git rev-parse HEAD)
}

@test "fetching remote with a deleted file AND new file" {
	local -r FILENAME1="foo.txt"
	local -r FILENAME2="bar.txt"

	local -r FILENAME1_BODY="$(uuidgen)"
	local -r FILENAME2_BODY="$(uuidgen)"
	assert_not_equal "${FILENAME1_BODY}" "${FILENAME2_BODY}"

	# add FILENAME1 to remote
	echo "${FILENAME1_BODY}" >"$(dirname $RCLONE_SOURCE)/${FILENAME1}"
	cd "$(dirname $RCLONE_SOURCE)"
	GIT_DIR=$RCLONE_SOURCE git add "$(dirname $RCLONE_SOURCE)/${FILENAME1}"
	GIT_DIR=$RCLONE_SOURCE git commit -m "new file"
	GIT_DIR=$RCLONE_SOURCE git push
	rclone sync $RCLONE_BARE $RCLONE_REMOTE

	# fetch + pull
	# ensure that FILENAME1 exists locally
	cd "${LOCAL_DIR}/../"
	run fetch_local
	assert_failure
	pull_local
	assert_equal "$(cat "${FILENAME1}")" \
		"${FILENAME1_BODY}"
	cd $ROOT_DIR

	# add a commit to remote, with a FILENAME1 deleted, and FILENAME2 added
	cd "$(dirname $RCLONE_SOURCE)"
	rm "$(dirname $RCLONE_SOURCE)/${FILENAME1}"
	echo "${FILENAME2_BODY}" >"$(dirname $RCLONE_SOURCE)/${FILENAME2}"
	GIT_DIR=$RCLONE_SOURCE git add "$(dirname $RCLONE_SOURCE)/"
	GIT_DIR=$RCLONE_SOURCE git commit -m "again again"
	GIT_DIR=$RCLONE_SOURCE git push
	rclone sync $RCLONE_BARE $RCLONE_REMOTE

	assert_not_equal $(GIT_DIR=$LOCAL_DIR git rev-parse HEAD) \
		$(GIT_DIR=$RCLONE_SOURCE git rev-parse HEAD)

	# fetch + pull
	# ensure that FILENAME1 is deleted, and FILENAME2 is added
	cd "${LOCAL_DIR}/../"
	run fetch_local
	assert_failure
	pull_local
	refute [[ -f "${FILENAME1}" ]]
	assert_equal "$(cat "${FILENAME2}")" \
		"${FILENAME2_BODY}"

	cd $ROOT_DIR
}

@test "fetching a new branch" {
	# add a branch to the remote
	local -r new_branch=$(uuidgen)
	GIT_DIR=$RCLONE_SOURCE git checkout -b $new_branch
	GIT_DIR=$RCLONE_SOURCE git push -u origin $new_branch
	rclone sync $RCLONE_BARE $RCLONE_REMOTE

	# ensure the branch doesn't exist locally yet
	check_branch() {
		GIT_DIR=$LOCAL_DIR git rev-parse --verify $new_branch
	}
	run check_branch
	assert_failure

	# fetch
	# ensure the branch exists locally now
	GIT_DIR=$LOCAL_DIR git fetch
	GIT_DIR=$LOCAL_DIR git checkout $new_branch
	assert_equal $(GIT_DIR=$LOCAL_DIR git rev-parse --abbrev-ref HEAD) \
		$new_branch
}
