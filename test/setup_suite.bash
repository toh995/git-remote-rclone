setup_suite() {
	# Override $PATH to use the current repo's executable
	DIR=$(dirname $BATS_TEST_FILENAME)
	PATH="$DIR/../:$PATH"

	# Set up restic
	export RESTIC_REPOSITORY="${BATS_SUITE_TMPDIR}/$(uuidgen)"
	export RESTIC_PASSWORD="foo"
	restic init

	export XDG_CACHE_HOME="${BATS_SUITE_TMPDIR}/cache"
	export XDG_CONFIG_HOME="${BATS_SUITE_TMPDIR}/config"

	# Set up restic password
	readonly PASS_FILE="${XDG_CONFIG_HOME}/git-remote-restic/restic-password"
	mkdir -p "$(dirname $PASS_FILE)" &&
		echo $RESTIC_PASSWORD >"${PASS_FILE}"

	# Set up git
	readonly GITFILE="${XDG_CONFIG_HOME}/git/config"
	mkdir -p "$(dirname "${GITFILE}")" &&
		touch "${GITFILE}"
	echo "[user]" >>"${GITFILE}"
	echo "name = shrek" >>"${GITFILE}"
	echo "email = shrek@shrek.com" >>"${GITFILE}"
}
