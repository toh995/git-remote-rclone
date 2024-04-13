setup_suite() {
	export RESTIC_REPOSITORY="${BATS_SUITE_TMPDIR}/$(uuidgen)"
	export RESTIC_PASSWORD="foo"
	restic init

	export XDG_CACHE_HOME="${BATS_SUITE_TMPDIR}"
}
