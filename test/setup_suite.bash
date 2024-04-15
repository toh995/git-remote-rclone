setup_suite() {
	# Override $PATH to use the current repo's executable
	DIR=$(dirname $BATS_TEST_FILENAME)
	PATH="$DIR/../:$PATH"

	export XDG_CACHE_HOME="${BATS_SUITE_TMPDIR}/cache"
	export XDG_CONFIG_HOME="${BATS_SUITE_TMPDIR}/config"

	readonly RCLONE_REMOTE_DIR="${BATS_SUITE_TMPDIR}/$(uuidgen)"
	readonly KOPIA_REMOTE_DIR="${BATS_SUITE_TMPDIR}/$(uuidgen)"
	readonly PASSWORD="foo"
	export KOPIA_PASSWORD="${PASSWORD}"

	# Set up rclone
	# Create a local encrypted remote
	export RCLONE_REMOTE="foobarbaz:"

	readonly RCLONE_CFG="${XDG_CONFIG_HOME}/rclone/rclone.conf"
	mkdir -p "$(dirname "${RCLONE_CFG}")" &&
		touch "${RCLONE_CFG}"
	echo "[foobarbaz]" >>"${RCLONE_CFG}"
	echo "type = crypt" >>"${RCLONE_CFG}"
	echo "remote = ${RCLONE_REMOTE_DIR}" >>"${RCLONE_CFG}"
	echo "password = $(rclone obscure "${PASSWORD}")" >>"${RCLONE_CFG}"

	# Set up kopia
	kopia repository create filesystem --path "${KOPIA_REMOTE_DIR}" --cache-directory "${XDG_CACHE_HOME}"
	kopia repository connect filesystem --path "${KOPIA_REMOTE_DIR}"

	# Set up git
	readonly GITFILE="${XDG_CONFIG_HOME}/git/config"
	mkdir -p "$(dirname "${GITFILE}")" &&
		touch "${GITFILE}"
	echo "[user]" >>"${GITFILE}"
	echo "name = shrek" >>"${GITFILE}"
	echo "email = shrek@shrek.com" >>"${GITFILE}"
}
