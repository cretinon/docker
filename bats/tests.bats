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
  assert_success
}

####################################################################################################
########################################### VOLUME #################################################
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

@test "_volume_get_mount_point" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker volume_get_mount_point --volume_name testvol
  assert_success
}

@test "_volume_remove" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker volume_remove --volume_name testvol
  assert_success
}

@test "_volume_remove again" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker volume_remove --volume_name testvol
  assert_failure
}

####################################################################################################
########################################### NETWORK ################################################
####################################################################################################
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

####################################################################################################
############################################# SYSTEM ###############################################
####################################################################################################
@test "_system_df" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker system_df
  assert_output --partial "Containers"
}

@test "_system_reclaim" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker system_reclaim
  assert_success
}

####################################################################################################
############################################ CONTAINER #############################################
####################################################################################################
@test "_container_start" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_start --docker_file dockerfile/jinade_check_my_ip --target dockerhub --distrib debian
  assert_success
}

@test "_container_start again" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_start --docker_file dockerfile/jinade_check_my_ip --target dockerhub --distrib debian
  assert_failure
}

@test "_container_list" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_list
  assert_output --partial "jinade_check_my_ip running"
}

@test "_container_list_verbose" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_list
  assert_output --partial "jinade_check_my_ip"
}

@test "_network_create last" {
  run $MY_GIT_DIR/shell/my_warp.sh --lib docker network_create --network_name testnet --driver bridge --subnet 172.254.0.0/16 --gateway 172.254.0.1
  assert_success
}

@test "_container_connect_to_network" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_connect_to_network --container_name jinade_check_my_ip --network_name testnet
  assert_success
}

@test "_container_get_network" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_get_network --container_name jinade_check_my_ip
  assert_output --partial "bridge
testnet"
}

@test "_container_get_ip" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_get_ip --container_name jinade_check_my_ip --network_name testnet
  assert_output --partial "172.254"
}

@test "_container_get_network_ip" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_get_network_ip --container_name jinade_check_my_ip
  assert_output --partial "testnet;172.254"
}

@test "_container_rshell" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_rshell --docker_file dockerfile/jinade_check_my_ip --cmd ls
  assert_output --partial "bin"
}

@test "_container_stop" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_stop --docker_file dockerfile/jinade_check_my_ip
  assert_success
}

@test "_container_stop again" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_stop --docker_file dockerfile/jinade_check_my_ip
  assert_failure
}

@test "_container_rshell again" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_rshell --docker_file dockerfile/jinade_check_my_ip --cmd ls
  assert_failure
}

@test "_container_list again" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_list
  assert_output --partial "jinade_check_my_ip exited"
}

@test "_container_get_name_from_image" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_get_name_from_image --image_name cretinon/jinade_check_my_ip
  assert_output --partial "jinade_check_my_ip"
}

@test "_container_shell" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_shell --docker_file dockerfile/jinade_check_my_ip --target dockerhub --distrib debian --cmd ls
  assert_failure
}

#@test "_container_rm" {
#  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_rm --docker_file dockerfile/jinade_check_my_ip
#  assert_failure
#}

@test "_container_log_show" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_log_show --container_name jinade_check_my_ip
  assert_output --partial "badauth"
}

@test "_container_log_show again" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker container_log_show --container_name idonotexist
  assert_failure
}

####################################################################################################
############################################## BUILD ###############################################
####################################################################################################
@test "_build_all" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker build_all --target dockerhub
  assert_success
}

@test "_build_base force" {
  run $MY_GIT_DIR/shell/my_warp.sh -d -v --lib docker build --target dockerhub --distrib alpine --docker_file dockerfile/jinade_base --force true
  assert_success
}

####################################################################################################
############################################## FETCH ###############################################
####################################################################################################
#
# fetch.sh is the build-time downloader of the entrypoints: it goes through the apt cache of the
# lab when HTTP_PROXY points at it, and it must never hand an empty body to the `tar` of its
# caller (a file type the cache refuses is answered with an empty body). Its `wget` is stubbed:
# the stub records the arguments and the proxy it was handed, and -- since fetch.sh downloads
# with `-O <file>` -- writes the body into that file.

setup_fetch() {
  export WGET_ARGS="$BATS_TEST_TMPDIR/wget.args"
  export WGET_ATTEMPTS="$BATS_TEST_TMPDIR/wget.attempts"
  export WGET_BODY="$BATS_TEST_TMPDIR/body"
  export FETCH="$MY_GIT_DIR/docker/entrypoint/fetch.sh"
  unset WGET_STATUS
  unset WGET_FAIL_TIMES
  unset WGET_BODY2
  printf 'BODY' >"$WGET_BODY"
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  cat >"$BATS_TEST_TMPDIR/bin/wget" <<'EOF'
#!/bin/sh
# wget stub: records the arguments and the proxy it was handed, counts its attempts, then
# writes a body into the file named by `-O` (on stdout without one) like the real one. The
# body of the first attempt is `WGET_BODY`, the one of the later attempts `WGET_BODY2` when
# it is set -- which is how a cache that serves a truncated archive is simulated.
printf '%s (proxy=%s)\n' "$*" "${HTTP_PROXY:-}" >>"$WGET_ARGS"
__n=0
[ -f "$WGET_ATTEMPTS" ] && __n=$(cat "$WGET_ATTEMPTS")
__n=$((__n + 1))
printf '%s' "$__n" >"$WGET_ATTEMPTS"
__out=""
while [ $# -gt 0 ]; do
  case "$1" in
    -O) __out="$2" ; shift 2 ;;
    *) shift ;;
  esac
done
__body="$WGET_BODY"
if [ -n "$WGET_BODY2" ] && [ "$__n" -gt 1 ]; then __body="$WGET_BODY2" ; fi
if [ -n "$__out" ]; then cat "$__body" >"$__out" ; else cat "$__body" ; fi
# a stub told to fail fails every attempt, unless `WGET_FAIL_TIMES` bounds the failures
if [ -n "$WGET_STATUS" ]; then
  if [ -z "$WGET_FAIL_TIMES" ] || [ "$__n" -le "$WGET_FAIL_TIMES" ]; then exit "$WGET_STATUS" ; fi
fi
exit 0
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/wget"
}

@test "fetch.sh goes through the apt cache with its HTTPS marker" {
  setup_fetch
  printf 'hello' | gzip -c >"$BATS_TEST_TMPDIR/whole.tar.gz"
  export WGET_BODY="$BATS_TEST_TMPDIR/whole.tar.gz"
  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" HTTP_PROXY="http://192.168.2.28:3142" \
    sh "$FETCH" "https://github.com/Sonarr/Sonarr/releases/download/v4.0.13.2932/Sonarr.main.4.0.13.2932.linux-x64.tar.gz"
  assert_success
  run cat "$WGET_ARGS"
  assert_output --partial "http://192.168.2.28:3142/HTTPS///github.com/Sonarr/Sonarr/releases/download/v4.0.13.2932/Sonarr.main.4.0.13.2932.linux-x64.tar.gz"
  # the proxy is blanked for that call: handed the marked URL *as a proxy*, the cache answers
  # `403 ... prohibited port`
  assert_output --partial "(proxy=)"
  # and no timeout is ever handed to wget: the link of the lab is slow, a read timeout aborts
  # a transfer that is merely large, and the truncated file it leaves is what the cache then
  # replays as complete
  refute_output --partial "--timeout"
  # the whole archive came out on the first attempt: the caller of this test is the body, and
  # a body is what `tar xz` reads downstream
  run cat "$WGET_ATTEMPTS"
  assert_output "1"
}

@test "fetch.sh goes straight out when no cache is configured" {
  setup_fetch
  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" sh "$FETCH" "https://example.com/release"
  assert_success
  assert_output "BODY"
  run cat "$WGET_ARGS"
  assert_output --partial "https://example.com/release"
  refute_output --partial "HTTPS///"
}

@test "fetch.sh hands an http URL to the cache as a proxy" {
  setup_fetch
  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" HTTP_PROXY="http://192.168.2.28:3142" sh "$FETCH" "http://example.com/release"
  assert_success
  assert_output "BODY"
  run cat "$WGET_ARGS"
  assert_output --partial " http://example.com/release"
  assert_output --partial "(proxy=http://192.168.2.28:3142)"
}

@test "fetch.sh fails when the download fails" {
  setup_fetch
  export WGET_STATUS=8
  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" sh "$FETCH" "https://example.com/release"
  assert_failure
  assert_output --partial "fetch.sh: wget failed for https://example.com/release"
}

@test "fetch.sh retries a download that failed once" {
  setup_fetch
  export WGET_STATUS=8
  export WGET_FAIL_TIMES=1
  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" sh "$FETCH" "https://example.com/release"
  # the second attempt succeeds: the transient `403`/`5xx` of the cache must not throw away
  # the apt work of the layers below
  assert_success
  assert_output --partial "BODY"
  assert_output --partial "fetch.sh: retrying https://example.com/release (attempt 2/3)"
  run cat "$WGET_ATTEMPTS"
  assert_output "2"
}

@test "fetch.sh fails on an empty body without printing it" {
  setup_fetch
  export WGET_BODY=/dev/null
  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" sh "$FETCH" "https://example.com/release"
  assert_failure
  assert_output --partial "fetch.sh: empty body for https://example.com/release"
  # nothing is printed on stdout: an empty stream is what the `tar xz` of a caller reads as an
  # archive of its own, and it used to be the whole story of a build that produced an empty image
  refute_output --partial "BODY"
}

@test "fetch.sh refuses an empty URL" {
  setup_fetch
  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" sh "$FETCH" ""
  assert_failure
  assert_output --partial "fetch.sh: URL EMPTY"
}

@test "fetch.sh goes straight out when the cache serves a truncated archive" {
  setup_fetch
  printf 'hello' | gzip -c >"$BATS_TEST_TMPDIR/whole.tar.gz"
  head -c 10 "$BATS_TEST_TMPDIR/whole.tar.gz" >"$BATS_TEST_TMPDIR/truncated.tar.gz"
  export WGET_BODY="$BATS_TEST_TMPDIR/truncated.tar.gz"
  export WGET_BODY2="$BATS_TEST_TMPDIR/whole.tar.gz"
  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" HTTP_PROXY="http://192.168.2.28:3142" \
    sh "$FETCH" "https://example.com/release.tar.gz"
  # a body that is not a whole archive is a failure -- wget reports the cache's truncated file
  # as `saved`, and the `tar` of the caller is where that would otherwise show up
  assert_success
  assert_output --partial "fetch.sh: retrying https://example.com/release.tar.gz (attempt 2/3)"
  assert_output --partial "fetch.sh: the cache did not deliver https://example.com/release.tar.gz, going straight out"
  # the first attempt went through the cache, the second one straight out
  run sed -n 1p "$WGET_ARGS"
  assert_output --partial "HTTPS///example.com/release.tar.gz"
  run sed -n 2p "$WGET_ARGS"
  refute_output --partial "HTTPS///"
  assert_output --partial "https://example.com/release.tar.gz"
  # ... and there was no third attempt: the whole archive came out
  run cat "$WGET_ATTEMPTS"
  assert_output "2"
}

@test "fetch.sh goes straight out when the cache serves a truncated zip" {
  setup_fetch
  if ! command -v unzip >/dev/null 2>&1 ; then skip "unzip is not installed" ; fi
  printf 'hello' >"$BATS_TEST_TMPDIR/file.txt"
  python3 -m zipfile -c "$BATS_TEST_TMPDIR/whole.zip" "$BATS_TEST_TMPDIR/file.txt"
  head -c 20 "$BATS_TEST_TMPDIR/whole.zip" >"$BATS_TEST_TMPDIR/truncated.zip"
  export WGET_BODY="$BATS_TEST_TMPDIR/truncated.zip"
  export WGET_BODY2="$BATS_TEST_TMPDIR/whole.zip"
  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" HTTP_PROXY="http://192.168.2.28:3142" \
    sh "$FETCH" "https://example.com/release.zip"
  assert_success
  assert_output --partial "fetch.sh: the cache did not deliver https://example.com/release.zip, going straight out"
  run sed -n 2p "$WGET_ARGS"
  refute_output --partial "HTTPS///"
}

@test "fetch.sh fails when the archive never arrives whole" {
  setup_fetch
  printf 'hello' | gzip -c >"$BATS_TEST_TMPDIR/whole.tar.gz"
  head -c 10 "$BATS_TEST_TMPDIR/whole.tar.gz" >"$BATS_TEST_TMPDIR/truncated.tar.gz"
  export WGET_BODY="$BATS_TEST_TMPDIR/truncated.tar.gz"
  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" sh "$FETCH" "https://example.com/release.tar.gz"
  # three attempts, none of them a whole archive: the caller is told why, and nothing that
  # `tar` would read as a valid but empty stream reaches it
  assert_failure
  assert_output --partial "fetch.sh: incomplete archive for https://example.com/release.tar.gz"
  run cat "$WGET_ATTEMPTS"
  assert_output "3"
}
