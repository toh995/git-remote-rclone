setup_suite() {
	# Override $PATH to use the current repo's executable
	local -r DIR="$(dirname "${BATS_TEST_FILENAME}")"
	export PATH="$DIR/../:$PATH"

	export XDG_CACHE_HOME="${BATS_SUITE_TMPDIR}/cache"
	export XDG_CONFIG_HOME="${BATS_SUITE_TMPDIR}/config"

	local -r RCLONE_REMOTE_DIR="${BATS_SUITE_TMPDIR}/$(uuidgen)"
	local -r KOPIA_REMOTE_DIR="${BATS_SUITE_TMPDIR}/$(uuidgen)"
	readonly PASSWORD="foo"
	export KOPIA_PASSWORD="${PASSWORD}"

	# Set up rclone
	# Create a local encrypted remote
	export RCLONE_REMOTE="foobarbaz:"

	readonly RCLONE_CFG="${XDG_CONFIG_HOME}/rclone/rclone.conf"
	mkdir -p "$(dirname "${RCLONE_CFG}")" &&
		touch "${RCLONE_CFG}"
	{
		echo "[foobarbaz]"
		echo "type = crypt"
		echo "remote = ${RCLONE_REMOTE_DIR}"
		echo "password = $(rclone obscure "${PASSWORD}")"
	} >>"${RCLONE_CFG}"

	# Set up kopia
	kopia repository create filesystem --path "${KOPIA_REMOTE_DIR}" --cache-directory "${XDG_CACHE_HOME}"
	kopia repository connect filesystem --path "${KOPIA_REMOTE_DIR}"

	# Set up git
	readonly GITFILE="${XDG_CONFIG_HOME}/git/config"
	mkdir -p "$(dirname "${GITFILE}")" &&
		touch "${GITFILE}"
	{
		echo "[user]"
		echo "name = shrek"
		echo "email = shrek@shrek.com"
	} >>"${GITFILE}"
}
