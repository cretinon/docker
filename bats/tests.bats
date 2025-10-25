#!/usr/bin/env bats

# global var
VERBOSE=false
DEBUG=false
FUNC_LIST=()
unset LIB
#GIT_DIR="${HOME}/project/git"
CUR_NAME=${FUNCNAME[0]}

# load our shell functions and all libs
source $GIT_DIR/shell/lib_shell.sh
source $GIT_DIR/docker/lib_docker.sh
#_load_libs

setup() {
    load '/usr/lib/bats/bats-support/load'
    load '/usr/lib/bats/bats-assert/load'
}


@test "_network_list" {
  run _network_list
  assert_success
}
