#!/bin/bash

# shellcheck source=/dev/null disable=SC2294

#
# usage: _volume_create --volume_name name ($1)
#
_volume_create () {
    _func_start

    if _notexist "$1"; then _error "volume_name empty"; else _debug "volume_name:$1"; fi

    if docker volume ls | grep "$1" > /dev/nulll; then
        _warning "volume already exist"
    else
        docker volume create "$1"
    fi

    _func_end
}

#
# usage: _network_list
#
_network_list () {
    _func_start

    local __net

    __net=$(docker network list | awk '{print $2}' | grep -vw ID)

    echo "$__net"

    _func_end
}

#
# usage: _network_create --network_name name ($1) --driver driver ($2) --subnet 172.xx.0.0/16 ($3) --gateway 172.xx.xxx.xxx ($4)
#
_network_create () {
    _func_start

    if _notexist "$1"; then _error "network_name EMPTY"; else _debug "network_name:$1"; fi
    if _notexist "$2"; then _error "driver EMPTY (must be in:bridge, overlay, host, null)"; else _debug "driver:$2"; fi
    if _notexist "$3"; then _error "subnet EMPTY"; else _debug "subnet:$3"; fi
    if _notexist "$4"; then _error "gateway EMPTY"; else _debug "gateway:$4"; fi

    if _network_list | grep -w "$1" > /dev/null; then
        _warning "network already exist"
    else
        docker network create -d "$2" --subnet="$3" --gateway="$4" "$1"
    fi

#    docker network create -o "com.docker.network.bridge.name"="docker1"  -o "com.docker.network.bridge.enable_icc"="true" -o "com.docker.network.driver.mtu"="1500" -o "com.docker.network.bridge.enable_ip_masquerade"="true" -o "com.docker.network.bridge.host_binding_ipv4"="0.0.0.0" -d $2 --subnet=$3 --gateway=$4 $1
#    docker network create -o "com.docker.network.bridge.enable_icc"="true" -o "com.docker.network.driver.mtu"="1500" -o "com.docker.network.bridge.enable_ip_masquerade"="true" -o "com.docker.network.bridge.host_binding_ipv4"="0.0.0.0" -d $2 --subnet=$3 --gateway=$4 $1

    _func_end
}

#
# usage: _network_remove --network_name name ($1)
#
_network_remove () {
    _func_start

    if _notexist "$1"; then _error "network_name EMPTY"; else _debug "network_name:$1"; fi

    docker network remove "$1"

    _func_end
}

#
# usage: _container_list
#
_container_list () {
    _func_start

    docker ps --format json | jq -M -r ' .Names'

    _func_end
}

#
# usage: _container_log_show --container_name name ($1)
#
_container_log_show () {
    _func_start

    if _notexist "$1"; then _error "container_name EMPTY ('main --docker container_list' to list active containers)"; else _debug "container_name:$1"; fi

    docker logs -f "$1"

    _func_end
}

#
# usage: _container_filelog_show
#
_container_filelog_show () {
    ls -ailh /var/lib/docker/containers/*/*-json.log
}

#
# usage: _container_filelog_truncate
#
_container_filelog_truncate () {
    truncate -s 0 /var/lib/docker/containers/*/*-json.log
    _container_filelog_show
}

#
# usage: _system_df
#
_system_df () {
    docker system df
}

#
# usage: _system_reclaim
#
_system_reclaim () {
    #docker system prune -a -f
    docker system prune -a
}

#
# usage: _compose_file_from_running_container --container_name name ($1)
#
_compose_file_from_running_container () {
    _func_start

    if _notexist "$1"; then _error "container_name EMPTY"; else _debug "container_name:$1"; fi

    echo ""
    echo "####"
    echo "paste it to https://www.composerize.com/"
    echo "####"
    echo ""

    docker run --rm -ti -v /var/run/docker.sock:/var/run/docker.sock bcicen/docker-replay -p "$1"

    _func_end
}

#
# _make_action action ($1) docker_file ($2)
#
_make_action () {
    _func_start

    if _notexist "$2"; then _error "docker_file EMPTY"; else _debug "docker_file:$2"; fi
    if _filenotexist "$2"; then _error "docker_file does not exist"; _debug "docker_file exist:$2"; fi
    if _workingdir_isnot "$DOCKER_DIR"; then _error "running make_build outside of $DOCKER_DIR is not supported"; fi

    local __image
    local __opsys
    local __svcname
    local __arch
    local __distrib

    __image=$(echo "$2" | cut -d. -f2)
    __opsys=$(echo "$__image" | cut -d_ -f1)
    __svcname=$(echo "$__image" | cut -d_ -f2-99)
    __arch=$(echo "$2" | cut -d. -f3)
    __distrib=$(echo "$2" | cut -d. -f4)

    _debug "image:$__image"
    _debug "opsys:$__opsys"
    _debug "svcname:$__svcname"
    _debug "arch:$__arch"
    _debug "distrib:$__distrib"

    if $VERBOSE; then
        case $1 in
            build|push|shell|rshell|start|stop)
                make "$1" ARCH="$__arch" DISTRIB="$__distrib" OPSYS="$__opsys" SVCNAME="$__svcname"
                if [ $? -ne 0 ]; then
                    _error "'make $1 ARCH=$__arch DISTRIB=$__distrib OPSYS=$__opsys SVCNAME=$__svcname' goes wrong, stop here"
                fi
                ;;
            *)
                    _error "Action $1 not defined"
                    ;;
        esac
    else
        case $1 in
            build|push|shell|rshell|start|stop)
                make "$1" ARCH="$__arch" DISTRIB="$__distrib" OPSYS="$__opsys" SVCNAME="$__svcname" 1>/dev/null 2>/dev/null
                if [ $? -ne 0 ]; then
                    _error "'make $1 ARCH=$__arch DISTRIB=$__distrib OPSYS=$__opsys SVCNAME=$__svcname' goes wrong, run again with -v"
                fi
                ;;
            *)
                _error "Action $1 not defined"
                ;;
        esac
    fi

    _func_end
}

#
# usage: _make_start --docker_file file ($1)
#
_make_start () {
    _make_action "start" "$1"
}

#
# usage: _make_stop --docker_file file ($1)
#
_make_stop () {
    _make_action "stop" "$1"
}

#
# usage: _make_rshell --docker_file file ($1)
#
_make_rshell () {
    _make_action "rshell" "$1"
}

#
# usage: _make_shell --docker_file file ($1)
#
_make_shell () {
    _make_action "shell" "$1"
}

#
# usage: _make_push --docker_file file ($1)
#
_make_push () {
    _make_action "push" "$1"
}

#
# usage: _make_build --docker_file file ($1)
#
_make_build () {
    _make_action "build" "$1"
}

#
# usage: _make_build_all
#
_make_build_all () {
    _func_start

    if _workingdir_isnot "$DOCKER_DIR"; then _error "running make_build outside of $DOCKER_DIR is ot supported"; fi

    local __file

    for __file in $(ls dockerfile/Dockerfile* | grep -v debug | sort -u); do
        _verbose "Building file:$__file"
        _make_build "$__file"
        _make_push "$__file"
    done

    for __file in $(ls dockerfile/Dockerfile* | grep debug | sort -u); do
        _verbose "Building file:$__file"
        _make_build "$__file"
        _make_push "$__file"
    done

    _func_end
}

#
# usage: _install
#
_install_docker () {
    local __answer

    _warning "If you'r using apt-cacher-ng as proxy, be sure you have something like :"
    _warning "    PassThroughPattern: ^download\.docker\.com:443$"
    _warning "in your /etc/apt-cacher-ng/acng.conf then /etc/init.d/apt-cacher-ng restart"
    _warning ""

    while true; do
        read -r -p "Continue ? (y/N)" __answer
        case $__answer in
            [Yy] )
                apt-get update
                apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common -y
                curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
                echo "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
                apt-get update
                apt-get install docker-ce docker-ce-cli containerd.io -y
                apt-get clean

                mkdir -p /etc/docker/
                echo "{
  \"hosts\": [\"tcp://0.0.0.0:2375\", \"unix:///var/run/docker.sock\"],
  \"dns-search\": [\"include/tranet.local\"]
}
" > /etc/docker/daemon.json

                mkdir /etc/systemd/system/docker.service.d/

                echo "[Service]
ExecStart=
ExecStart=/usr/bin/dockerd" > /etc/systemd/system/docker.service.d/override.conf

                systemctl daemon-reload
                systemctl restart docker.service
                break
                ;;
            [Nn] )
                echo "Doing nothing"
                break
                ;;
            "" )
                break
                ;;
            * ) echo "Please answer Y or N.";;
        esac
    done

    echo "DOCKER_DIR=\"$MAIN_DIR/docker\"" > "$CONF_DIR"/docker.conf
}

#
#
#
_process_lib_docker () {
    _load_conf "$GIT_DIR/docker/conf/docker.conf"

    eval set -- "$@"

    while true ; do
        case "$1" in
            --container_name ) CONTAINER_NAME=$2 ; shift ; shift ;;
            --network_name )   NETWORK_NAME=$2 ; shift ; shift ;;
            --volume_name )    VOLUME_NAME=$2 ; shift ; shift ;;
            --driver )         DRIVER=$2 ; shift ; shift ;;
            --subnet )         SUBNET=$2 ; shift ; shift ;;
            --gateway )        GATEWAY=$2 ; shift ; shift ;;
            --docker_file )    DOCKER_FILE=$2 ; shift ; shift ;;
            -- ) shift ; break ;;
            * ) shift ;;
        esac
    done

    while true ; do
        case "$1" in
            install ) _install_docker ; shift ;;
            compose_file_from_running_container ) _compose_file_from_running_container "$CONTAINER_NAME" ; shift ;;
            network_list )               _network_list ; shift ;;
            network_create )	         _network_create "$NETWORK_NAME" "$DRIVER" "$SUBNET" "$GATEWAY" ; shift ;;
            volume_create )	         _volume_create "$VOLUME_NAME" ; shift ;;
            network_remove )	         _network_remove "$NETWORK_NAME" ; shift ;;
            container_filelog_show )     _container_filelog_show ; shift ;;
            container_filelog_truncate ) _container_filelog_truncate ; shift ;;
            container_log_show )	 _container_log_show "$CONTAINER_NAME" ; shift ;;
            container_list )	         _container_list ; shift ;;
            system_df )	                 _system_df ; shift ;;
            system_reclaim )	         _system_reclaim ; shift ;;
            make_build_all) _make_build_all ; shift ;;
            make_build)	    _make_build "$DOCKER_FILE" ; shift ;;
            make_push)	    _make_push "$DOCKER_FILE" ; shift ;;
            make_shell)	    _make_shell "$DOCKER_FILE" ; shift ;;
            make_rshell)    _make_rshell "$DOCKER_FILE" ; shift ;;
            make_start)	    _make_start "$DOCKER_FILE" ; shift ;;
            make_stop)	    _make_stop "$DOCKER_FILE" ; shift ;;
            -- ) shift ;;
            *)   if [ "a$1" != "a" ]; then _warning "Function $1 does not exist" ; _usage ; break ; else break; fi ;;
        esac
    done
}
