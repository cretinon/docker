#!/usr/bin/env bats

# global var
VERBOSE=false
DEBUG=false
FUNC_LIST=()
unset LIB
CUR_NAME=${FUNCNAME[0]}

# load our shell functions and all libs
source $MY_GIT_DIR/shell/lib_shell.sh
source $MY_GIT_DIR/docker/lib_docker.sh

setup() {
    load '/usr/lib/bats/bats-support/load'
    load '/usr/lib/bats/bats-assert/load'
}


####################################################################################################
########################################### DOCKER ADMIN ###########################################
####################################################################################################

@test "_volume_create" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker volume_create --volume_name testvol
  assert_success
}

@test "_volume_list" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker volume_list
  assert_output --partial "testvol"
}

@test "_volume_remove" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker volume_remove --volume_name testvol
  assert_success
}

@test "_network_create" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker network_create --network_name testnet --driver bridge --subnet 172.254.0.0/16 --gateway 172.254.0.1
  assert_success
}

@test "_network_list" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker network_list
  assert_output --partial "testnet"
}

@test "_network_remove" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker network_remove --network_name testnet
  assert_success
}