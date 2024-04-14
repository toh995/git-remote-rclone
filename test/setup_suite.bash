setup_suite() {
	# Override $PATH to use the current repo's executable
	DIR=$(dirname $BATS_TEST_FILENAME)
	PATH="$DIR/../:$PATH"

	export XDG_CACHE_HOME="${BATS_SUITE_TMPDIR}/cache"
	export XDG_CONFIG_HOME="${BATS_SUITE_TMPDIR}/config"

	# Set up rclone
	# Create a local encrypted remote
	export RCLONE_REMOTE="foobarbaz:"

	readonly RCLONE_CFG="${XDG_CONFIG_HOME}/rclone/rclone.conf"
	mkdir -p "$(dirname "${RCLONE_CFG}")" &&
		touch "${RCLONE_CFG}"
	echo "[foobarbaz]" >>"${RCLONE_CFG}"
	echo "type = crypt" >>"${RCLONE_CFG}"
	echo "remote = ${BATS_SUITE_TMPDIR}/$(uuidgen)" >>"${RCLONE_CFG}"
	echo "password = $(rclone obscure "foo")" >>"${RCLONE_CFG}"

	# Set up git
	readonly GITFILE="${XDG_CONFIG_HOME}/git/config"
	mkdir -p "$(dirname "${GITFILE}")" &&
		touch "${GITFILE}"
	echo "[user]" >>"${GITFILE}"
	echo "name = shrek" >>"${GITFILE}"
	echo "email = shrek@shrek.com" >>"${GITFILE}"
}
