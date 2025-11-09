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
############################################## INSTALL #############################################
####################################################################################################
@test "_install_docker" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker install
  assert_failure
}

####################################################################################################
########################################### DOCKER ADMIN ###########################################
####################################################################################################

@test "_volume_create" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker volume_create --volume_name testvol
  assert_success
}

@test "_volume_create again" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker volume_create --volume_name testvol
  assert_failure
}

@test "_volume_list" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker volume_list
  assert_output --partial "testvol"
}

@test "_volume_remove" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker volume_remove --volume_name testvol
  assert_success
}

@test "_volume_remove again" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker volume_remove --volume_name testvol
  assert_failure
}

@test "_network_create" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker network_create --network_name testnet --driver bridge --subnet 172.254.0.0/16 --gateway 172.254.0.1
  assert_success
}

@test "_network_create again" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker network_create --network_name testnet --driver bridge --subnet 172.254.0.0/16 --gateway 172.254.0.1
  assert_failure
}

@test "_network_list" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker network_list
  assert_output --partial "testnet"
}

@test "_network_remove" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker network_remove --network_name testnet
  assert_success
}

@test "_network_remove again" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker network_remove --network_name testnet
  assert_failure
}

@test "_system_df" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker system_df
  assert_output --partial "Containers"
}

@test "_system_reclaim" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker system_reclaim
  assert_success
}

@test "_container_start" {
  run cd $MY_GIT_DIR/docker && $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_start --docker_file dockerfile/jinade_check_my_ip --target dockerhub --distrib debian && cd -
  assert_success
}

@test "_container_list" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_list
  assert_output --partial "jinade_check_my_ip running"
}

@test "_container_rshell" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_rshell --docker_file dockerfile/jinade_check_my_ip --cmd ls
  assert_output --partial "bin"
}

@test "_container_stop" {
  run cd $MY_GIT_DIR/docker && $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_stop --docker_file dockerfile/jinade_check_my_ip && cd -
  assert_success
}

@test "_container_list again" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_list
  assert_output --partial "jinade_check_my_ip exited"
}

@test "_container_shell" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_shell --docker_file dockerfile/jinade_base --target dockerhub --distrib debian --cmd ls
  assert_output --partial "bin"
}

@test "_build_base" {
  run cd $MY_GIT_DIR/docker && $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker build --target dockerhub --distrib alpine --docker_file dockerfile/jinade_base --force true && cd -
  assert_success
}
