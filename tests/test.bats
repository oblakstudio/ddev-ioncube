TEST_BREW_PREFIX="$(brew --prefix)"
load "${TEST_BREW_PREFIX}/lib/bats-support/load.bash"
load "${TEST_BREW_PREFIX}/lib/bats-assert/load.bash"

setup() {
  set -eu -o pipefail

  export ADDON_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)/.."
  export PROJECT=testproj
  export TEST_DIR="$HOME/tmp/$PROJECT"
  export DDEV_NON_INTERACTIVE=true

  mkdir -p $TEST_DIR && cd "$TEST_DIR" || (printf "unable to cd to $TEST_DIR\n" && exit 1)

  ddev delete -Oy $PROJECT >/dev/null 2>&1 || true
  ddev config --project-name=$PROJECT --omit-containers=db --disable-upload-dirs-warning
}

health_checks() {
  set +u # bats-assert has unset variables so turn off unset check

  # get the addon
  run bash -c "ddev get $1"
  assert_success

  # start the project
  run bash -c "ddev start -y"
  assert_success

  run bash -c "ddev exec php -v"
  assert_success
  assert_output --partial 'with the ionCube PHP Loader'

  run bash -c "ddev exec php -m"
  assert_success
  assert_output --partial 'ionCube Loader'
  assert_output --partial 'ionCube PHP Loader'

}

teardown() {
  set -eu -o pipefail
  cd "$TEST_DIR" || (printf "unable to cd to $TEST_DIR\n" && exit 1)
  ddev stop
  ddev delete -Oy "$PROJECT" >/dev/null 2>&1
  [ "$TEST_DIR" != "" ] && rm -rf "$TEST_DIR"
}

# bats test_tags=local
@test "install from directory" {
  set -eu -o pipefail
  cd "$TEST_DIR"
  echo "# ddev get $TEST_DIR with project "$PROJECT" in "$TEST_DIR"" >&3
  health_checks "$ADDON_DIR"
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  cd ${TEST_DIR} || (printf "unable to cd to ${TEST_DIR}\n" && exit 1)
  echo "# ddev get ddev/ddev-ioncube with project ${PROJECT} in ${TEST_DIR} ($(pwd))" >&3
  health_checks "ddev/ddev-ioncube"
}
