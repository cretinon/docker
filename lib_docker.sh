#!/bin/bash

# shellcheck source=/dev/null disable=SC2294

####################################################################################################
############################################## INSTALL #############################################
####################################################################################################
#
# usage: _install
#
_install_docker () {
    _func_start

    _warning ""
    _warning "If you'r using apt-cacher-ng as proxy, be sure you have something like :"
    _warning "    PassThroughPattern: ^download\.docker\.com:443$"
    _warning "in your /etc/apt-cacher-ng/acng.conf then /etc/init.d/apt-cacher-ng restart"
    _warning ""

    local __return

    if ! _func_exist "_playbook_localhost_docker" ; then _error "lib_ansible not installed" ; _func_end "1" ; return 1 ; fi

    _playbook_localhost_docker
    __return=$?

    _func_end "$__return" ; return "$__return"
}

#
# usage: _usage_docker
#
_usage_docker () {
    _func_start

    echo -e "\nIn order to use lib_docker.sh you first need to create $MY_GIT_DIR/docker/conf/my_docker.conf with
 HTTP_PROXY=\"http://your.proxy.net:port\"    or    HTTP_PROXY=\"\"
 HTTPS_PROXY=\"https://your.proxy.net:port\"  or    HTTPS_PROXY=\"\"
 LOCAL_REGISTRY=\"your.registry.net:port\"    or    LOCAL_REGISTRY=\"\"

Then call any function like : \n"

    _func_end "0" ; return 0
}

####################################################################################################
########################################### DOCKER ADMIN ###########################################
####################################################################################################
#
# usage: _volume_create --volume_name name ($1)
#
_volume_create () {
    _func_start

    if _notexist "$1"; then _error "volume_name empty"; _func_end "1" ; return 1 ; fi
    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi

    _debug "volume_name:$1"

    local __return

    if docker volume ls | $GREP "$1" > /dev/null; then
        _warning "volume already exist" ; _func_end "1" ; return 1
    else
        docker volume create "$1"
        __return=$?
    fi

    _func_end "$__return" ; return "$__return"
}

#
# usage: _volume_list
#
_volume_list () {
    _func_start

    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi

    local __return

    docker volume ls | awk '{print $2}' | $GREP -vw "VOLUME"
    __return=$?

    _func_end "$__return" ; return "$__return"
}

#
# usage: _volume_remove --volume_name name ($1)
#
_volume_remove () {
    _func_start

    if _notexist "$1"; then _error "volume_name empty"; _func_end "1" ; return 1 ; fi
    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi

    _debug "volume_name:$1"

    local __return

    if docker volume ls | $GREP "$1" > /dev/null; then
        docker volume remove "$1"
        __return=$?
    else
        _warning "volume doesnt exist" ; _func_end "1" ; return 1
    fi

    _func_end "$__return" ; return "$__return"
}

#
# usage: _volume_get_mount_point --volume_name name ($1)
#
_volume_get_mount_point () {
    _func_start

    if _notexist "$1"; then _error "volume_name empty"; _func_end "1" ; return 1 ; fi
    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi

    _debug "volume_name:$1"

    local __return

    if docker volume ls | $GREP "$1" > /dev/null; then
        docker volume inspect "$1" --format json | jq -r '.[].Mountpoint'
        __return=$?
    else
        _warning "volume doesnt exist" ; _func_end "1" ; return 1
    fi

    _func_end "$__return" ; return "$__return"
}

#
# usage: _network_create --network_name name ($1) --driver driver ($2) --subnet 172.xx.0.0/16 ($3) --gateway 172.xx.xxx.xxx ($4)
#
_network_create () {
    _func_start

    if _notexist "$1"; then _error "network_name EMPTY"; _func_end "1" ; return 1 ; fi
    if _notexist "$2"; then _error "driver EMPTY (must be in:bridge, overlay, host, null)"; _func_end "1" ; return 1 ; fi
    if _notexist "$3"; then _error "subnet EMPTY"; _func_end "1" ; return 1 ; fi
    if _notexist "$4"; then _error "gateway EMPTY"; _func_end "1" ; return 1 ; fi
    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi

    _debug "network_name:$1"
    _debug "driver:$2"
    _debug "subnet:$3"
    _debug "gateway:$4"

    local __return

    if _network_list | $GREP -w "$1" > /dev/null; then
        _warning "network already exist" ; _func_end "1" ; return 1
    else
        docker network create -d "$2" --subnet="$3" --gateway="$4" "$1"
        __return=$?
    fi

    _func_end "$__return" ; return "$__return"
}

#
# usage: _network_list
#
_network_list () {
    _func_start

    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi

    local __return

    docker network list | awk '{print $2}' | $GREP -vw ID
    __return=$?

    _func_end "$__return" ; return "$__return"
}

#
# usage: _network_exist --network_name name ($1)
#
_network_exist () {
    _func_start

    if _notexist "$1"; then _error "network_name EMPTY ('main --docker network_list' to list active networkss)"; _func_end "1" ; return 1 ; fi

    if _network_list | $GREP -w "$1" > /dev/null ; then _func_end "0" ; return 0 ; else _func_end "1" ; return 1 ; fi
}

#
# usage: _network_remove --network_name name ($1)
#
_network_remove () {
    _func_start

    if _notexist "$1"; then _error "network_name EMPTY";_func_end "1" ; return 1 ; fi
    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi

    _debug "network_name:$1"

    local __return

    if docker network list | $GREP -w "$1" > /dev/null; then
        docker network remove "$1"
        __return=$?
    else
        _warning "network alreadydoesnt exist" ; _func_end "1" ; return 1
    fi

    _func_end "$__return" ; return "$__return"
}

#
# usage: _system_df
#
_system_df () {
    _func_start

    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi

    local __return

    docker system df
    __return=$?

    _func_end "$__return" ; return "$__return"
}

#
# usage: _system_reclaim
#
_system_reclaim () {
    _func_start

    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi

    local __return

    docker system prune -a -f
    __return=$?

    _func_end "$__return" ; return "$__return"
}

#
# usage: _compose_file_from_running_container --container_name name ($1)
#
_compose_file_from_running_container () {
    _func_start

    if _notexist "$1"; then _error "container_name EMPTY"; _func_end "1" ; return 1 ; fi
    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi

    _debug "container_name:$1"

    local __return

    echo ""
    echo "####"
    echo "paste it to https://www.composerize.com/"
    echo "####"
    echo ""

    docker run --rm -ti -v /var/run/docker.sock:/var/run/docker.sock bcicen/docker-replay -p "$1"
    __return=$?

    _func_end "$__return" ; return "$__return"
}

####################################################################################################
############################################ CONTAINER #############################################
####################################################################################################
#
# usage: _container_list_verbose
#
_container_list_verbose () {
    _func_start

    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi

    local __return

    docker ps -a --format json | jq -r
    __return=$?

    _func_end "$__return" ; return "$__return"
}

#
# usage: _container_list
#
_container_list () {
    _func_start

    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi

    local __return

    docker ps -a --format json | jq -M -r '.Names + " " + .State'
    __return=$?

    _func_end "$__return" ; return "$__return"
}

#
# usage: _container_exist --container_name name ($1)
#
_container_exist () {
    _func_start

    if _notexist "$1"; then _error "container_name EMPTY ('main --docker container_list' to list active containers)"; _func_end "1" ; return 1 ; fi

    if _container_list | $GREP -w "$1" > /dev/null ; then _func_end "0" ; return 0 ; else _func_end "1" ; return 1 ; fi
}

#
# usage: _container_log_show --container_name name ($1)
#
_container_log_show () {
    _func_start

    if _notexist "$1"; then _error "container_name EMPTY ('main --docker container_list' to list active containers)"; _func_end "1" ; return 1 ; fi
    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi

    _debug "container_name:$1"

    local __return

    docker logs -f "$1"
    __return=$?

    _func_end "$__return" ; return "$__return"
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
# usage: _container_start --docker_file file ($1) --target local/dockerhub ($2) --distrib debian/alpine ($3)
#
_container_start () {
    _func_start

    if _notexist "$1"; then _error "DOCKER_FILE EMPTY"; _func_end "1" ; return 1 ; fi
    if _filenotexist "$1"; then _error "DOCKER_FILE:$1 does not exist"; _func_end "1" ; return 1 ; fi
    if _notexist "$2"; then _error "TARGET EMPTY"; _func_end "1" ; return 1 ; fi
    if _notexist "$3"; then _error "DISTRIB EMPTY"; _func_end "1" ; return 1 ; fi
    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi

    _debug "DOCKER_FILE:$1"
    _debug "TARGET:$2"
    _debug "DISTRIB:$3"

    local __image
    local __target
    local __hostname
    local __pgid
    local __puid
    local __return

    __image=$(echo "$1" | cut -d. -f1 | cut -d/ -f2)
    __hostname=$(echo "$__image" | cut -d_ -f2)
    __pgid=$(id -g)
    __puid=$(id -u)

    _debug "IMAGE:$__image"
    _debug "HOSTNAME:$__hostname"

    case "$2" in
        "local")
            __target="$LOCAL_REGISTRY" ;
            ;;
        "dockerhub")
           if _notexist "$DOCKER_USERNAME"; then _error "DOCKER_USERNAME EMPTY"; _func_end "1" ; return 1 ; fi
           __target="$DOCKER_USERNAME"
           ;;
        *) _error "bad target $2 (must be local/dockerhub)"; _func_end "1" ; return 1 ;;
    esac

    if _container_list | $GREP -w "$__image" | $GREP -w "exited" > /dev/null ; then
        _warning "Can't start, container exist, but was exited, restarting"
        docker restart "$__image" > /dev/null
        __return=$?
    else
        if _container_list | $GREP -w "$__image" | $GREP -w "running" > /dev/null ; then
            _warning "Can't start, container exist, and was exited, restarting"
            docker restart "$__image" > /dev/null
            __return=$?
        else
            docker run -d --name "$__image" --hostname "$__hostname" -e PGID="$__pgid" -e PUID="$__puid" "$__target"/"$__image":"$3" > /dev/null
            __return=$?
        fi
    fi

    _func_end "$__return" ; return "$__return"
}

#
# usage: _container_stop --docker_file file ($1)
#
_container_stop () {
    _func_start

    if _notexist "$1"; then _error "DOCKER_FILE EMPTY"; _func_end "1" ; return 1 ; fi
    if _filenotexist "$1"; then _error "DOCKER_FILE:$1 does not exist"; _func_end "1" ; return 1 ; fi
    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi

    _debug "DOCKER_FILE:$1"

    local __image
    local __return

    __image=$(echo "$1" | cut -d. -f1 | cut -d/ -f2)

    _debug "IMAGE:$__image"

    if _container_list | $GREP -w "$__image" | $GREP -w "exited" > /dev/null ; then
        _warning "Can't stop, container exist, but was already exited, doing nothing"
    else
        if _container_list | $GREP -w "$__image" | $GREP -w "running" > /dev/null ; then
            docker container stop "$__image" > /dev/null
            __return=$?
        else
            _warning "Can't stop, container doesn't exist, doing nothing"
        fi
    fi

    _func_end "$__return" ; return "$__return"
}

#
# usage: _container_shell --docker_file file ($1) --target local/dockerhub ($2) --distrib debian/alpine ($3) --cmd optional ($4)
#
_container_shell () {
    _func_start

    if _notexist "$1"; then _error "DOCKER_FILE EMPTY"; _func_end "1" ; return 1 ; fi
    if _filenotexist "$1"; then _error "DOCKER_FILE:$1 does not exist"; _func_end "1" ; return 1 ; fi
    if _notexist "$2"; then _error "TARGET EMPTY"; _func_end "1" ; return 1 ; fi
    if _notexist "$3"; then _error "DISTRIB EMPTY"; _func_end "1" ; return 1 ; fi
    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi

    _debug "DOCKER_FILE:$1"
    _debug "TARGET:$2"
    _debug "DISTRIB:$3"

    local __image
    local __target
    local __hostname
    local __pgid
    local __puid
    local __cmd
    local __return

    __image=$(echo "$1" | cut -d. -f1 | cut -d/ -f2)
    __hostname=$(echo "$__image" | cut -d_ -f2)
    __pgid=$(id -g)
    __puid=$(id -u)
    __image=$(echo "$1" | cut -d. -f1 | cut -d/ -f2)
    if _notexist "$4"; then
        __cmd="/bin/bash"
    else
        __cmd="$4"
    fi

    _debug "IMAGE:$__image"
    _debug "HOSTNAME:$__hostname"

    case "$2" in
        "local")
            __target="$LOCAL_REGISTRY" ;
            ;;
        "dockerhub")
           if _notexist "$DOCKER_USERNAME"; then _error "DOCKER_USERNAME EMPTY"; _func_end "1" ; return 1 ; fi
           __target="$DOCKER_USERNAME"
           ;;
        *) _error "bad target $2 (must be local/dockerhub)"; _func_end "1" ; return 1 ;;
    esac

    if _container_list | $GREP -w "$__image" | $GREP -w "exited" > /dev/null ; then
        _warning "Can't start, container exist, but was exited, removing first"
        docker container rm "$__image" > /dev/null
        docker run --rm -it --name "$__image" --hostname "$__hostname" -e PGID="$__pgid" -e PUID="$__puid" "$__target"/"$__image":"$3" "$__cmd"
        __return=$?
    else
        if _container_list | $GREP -w "$__image" | $GREP -w "running" > /dev/null ; then
            _error "Can't shell, container exist, and is running, doing nothing, you may want to rshell" ; _func_end "1" ; return 1
        else
            docker run --rm -it --name "$__image" --hostname "$__hostname" -e PGID="$__pgid" -e PUID="$__puid" "$__target"/"$__image":"$3" "$__cmd"
            __return=$?
        fi
    fi

    _func_end "$__return" ; return "$__return"
}

#
# usage: _container_rshell --docker_file file ($1) --cmd optional ($2)
#
_container_rshell () {
    _func_start

    if _notexist "$1"; then _error "DOCKER_FILE EMPTY"; _func_end "1" ; return 1 ; fi
    if _filenotexist "$1"; then _error "DOCKER_FILE:$1 does not exist"; _func_end "1" ; return 1 ; fi
    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi

    _debug "DOCKER_FILE:$1"

    local __image
    local __cmd
    local __return

    __image=$(echo "$1" | cut -d. -f1 | cut -d/ -f2)
    if _notexist "$2"; then
        __cmd="/bin/bash"
    else
        __cmd="$2"
    fi

    _debug "IMAGE:$__image"

    if _container_list | $GREP -w "$__image" | $GREP -w "exited" > /dev/null ; then
        _error "Can't rshell, container exist, but is exited, you need to restart first" ; _func_end "1" ; return 1
    else
        if _container_list | $GREP -w "$__image" | $GREP -w "running" > /dev/null ; then
            docker exec -u root -it "$__image" "$__cmd"
            __return=$?
        else
            _error "Can't rshell, container doesn't exist, doing nothing" ; _func_end "1" ; return 1
        fi
    fi

    _func_end "$__return" ; return "$__return"
}

#
# usage: _container_get_network_ip --container_name name ($1)
#
_container_get_network_ip () {
    _func_start

    if _notexist "$1"; then _error "CONTAINER_NAME EMPTY"; _func_end "1" ; return 1 ; fi
    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi
    if _notinstalled "jq"; then _error "jq not found"; _func_end "1" ; return 1 ; fi
    if ! _container_exist "$1" ; then _error "CONTAINER does not exist"; _func_end "1" ; return 1 ; fi

    local __return=0
    local __result

    __result=$(docker container inspect -f json "$1" 2>/dev/null)
    __return=$?

    echo "$__result"  | jq -r '.[].NetworkSettings.Networks | keys[] as $k | "\($k), \(.[$k] | .IPAddress)"' | sed -e 's/, /;/'

    _func_end "$__return" ; return $__return
}

#
# usage: _container_get_ip --container_name name ($1) --network_name name ($2)
#
_container_get_ip () {
    _func_start

    if _notexist "$1"; then _error "CONTAINER_NAME EMPTY"; _func_end "1" ; return 1 ; fi
    if _notexist "$2"; then _error "NETWORK_NAME EMPTY"; _func_end "1" ; return 1 ; fi
    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi
    if _notinstalled "jq"; then _error "jq not found"; _func_end "1" ; return 1 ; fi
    if ! _container_exist "$1" ; then _error "CONTAINER does not exist"; _func_end "1" ; return 1 ; fi

    docker container inspect -f json "$1" | jq -r '.[].NetworkSettings.Networks.'"$2"'.IPAddress'

    _func_end "0" ; return 0
}

#
# usage: _container_get_network --container_name name ($1)
#
_container_get_network () {
    _func_start

    if _notexist "$1"; then _error "CONTAINER_NAME EMPTY"; _func_end "1" ; return 1 ; fi
    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi
    if _notinstalled "jq"; then _error "jq not found"; _func_end "1" ; return 1 ; fi
    if ! _container_exist "$1" ; then _error "CONTAINER does not exist"; _func_end "1" ; return 1 ; fi

    docker container inspect -f json "$1" | jq -r '.[].NetworkSettings.Networks | keys[] as $k | "\($k)"'

    _func_end "0" ; return 0
}

#
# usage: _container_connect_to_network --container_name name ($1) --network_name name ($2)
#
_container_connect_to_network () {
    _func_start

    if _notexist "$1"; then _error "CONTAINER_NAME EMPTY"; _func_end "1" ; return 1 ; fi
    if _notexist "$2"; then _error "NETWORK_NAME EMPTY"; _func_end "1" ; return 1 ; fi
    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi
    if _notinstalled "jq"; then _error "jq not found"; _func_end "1" ; return 1 ; fi
    if ! _container_exist "$1" ; then _error "CONTAINER does not exist"; _func_end "1" ; return 1 ; fi
    if ! _network_exist "$2" ; then _error "NETWORK does not exist"; _func_end "1" ; return 1 ; fi

    docker network connect "$2" "$1"

    _func_end "0" ; return 0
}

#
# usage: _build --docker_file file ($1) --target local/dockerhub ($2) --distrib debian/alpine ($3) --force true/false ($4)
#
_build () {
    _func_start

    if _notexist "$1"; then _error "DOCKER_FILE EMPTY"; _func_end "1" ; return 1 ; fi
    if _filenotexist "$1"; then _error "DOCKER_FILE:$1 does not exist"; _func_end "1" ; return 1 ; fi
    if _notexist "$2"; then _error "TARGET EMPTY"; _func_end "1" ; return 1 ; fi
    if _notexist "$3"; then _error "DISTRIB EMPTY"; _func_end "1" ; return 1 ; fi
    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi

    _debug "DOCKER_FILE:$1"
    _debug "TARGET:$2"
    _debug "DISTRIB:$3"

    local __image
    local __opsys
    local __target
    local __http_proxy
    local __https_proxy
    local __alpine_version
    local __output_build
    local __dockerfile_version
    local __image_version
    local __force
    local __return

    __image=$(echo "$1" | cut -d. -f1 | cut -d/ -f2)
    __opsys=$(echo "$__image" | cut -d_ -f1 | cut -d/ -f2)
    __dockerfile_version=$($GREP "ARG VERSION=" "$1" | cut -d\" -f2)
    if ! __image_version=$(_get_image_version "$1" "$2" "$3") ; then _error "something went wrong with get_image_version" ; _func_end "1" ; return 1  ; fi

    if _notexist "$__dockerfile_version"; then _error "No version in $1"; _func_end "1" ; return 1 ; fi

    if _notexist "$4"; then __force=false ; else __force="$4" ; fi

    if [ "a$__image_version" = "a$__dockerfile_version" ]; then
        if [ "a$__force" != "atrue" ]; then
            _warning "trying to build same version as existing in $2 repository. Skipping."
            _func_end "0" ; return 0
        else
            _verbose "trying to build same version as existing in $2 repository. But FORCE."
        fi
    fi

    _debug "image:$__image"
    _debug "opsys:$__opsys"

    case "$2" in
        "local")
            __target="$LOCAL_REGISTRY" ;
            __http_proxy="$HTTP_PROXY" ;
            __https_proxy="$HTTP_PROXY" ;
            __output_build="type=registry"",registry.insecure=true"
            ;;
       "dockerhub")
           if _notexist "$DOCKER_USERNAME"; then _error "DOCKER_USERNAME EMPTY"; _func_end "1" ; return 1 ; fi
           docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"
           __target="$DOCKER_USERNAME"
           __http_proxy=""
           __https_proxy=""
           __output_build="type=registry,registry.insecure=false"
           ;;
        *) _error "bad target $2 (must be local/dockerhub)"; _func_end "1" ; return 1 ;;
    esac

    case "$3" in
        "debian")
            __base_tag="stable-slim"
            ;;
        "alpine")
            __base_tag="3.22"
            ;;
        *)_error "bad distrib $3 (must be debian/alpine)"; _func_end "1" ; return 1 ;;
    esac

    _debug "Going to build=>""$__target"/"$__image":"$3"

    #creating buildkit conf file, even if we re in CI
    sudo mkdir -p /etc/buildkit/
    sudo cat <<EOF | sudo tee /etc/buildkit/buildkitd.toml
debug = true
trace = true
insecure-entitlements = [ "network.host", "security.insecure", "device" ]

[log]
  format = "text"

[registry."$LOCAL_REGISTRY"]
  http = true
EOF

    if ! docker container ls | $GREP moby/buildkit 2>/dev/null 1>/dev/null; then
        docker run --rm --privileged multiarch/qemu-user-static:register --reset
    fi

    if docker buildx ls | $GREP multiarch 2>/dev/null 1>/dev/null; then
        docker buildx rm multiarch
    fi

   docker buildx create --use --bootstrap --node multiarch --name multiarch --driver docker-container --platform linux/arm/v7,linux/arm64/v8,linux/amd64 --buildkitd-config /etc/buildkit/buildkitd.toml

   docker buildx build --output "$__output_build" --rm --force-rm --compress -f "$1" -t "$__target"/"$__image":"$3" \
          --build-arg BASE_TAG="$__base_tag" \
          --build-arg DOCKERSRC="$__target"/"$__opsys""_base" \
          --build-arg DISTRIB="$3" \
          --build-arg PUID=0 \
          --build-arg PGID=0 \
          --build-arg HTTP_PROXY="$__http_proxy" \
          --build-arg HTTPS_PROXY="$__https_proxy" \
          --label org.label-schema.build-date="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
          --label org.label-schema.name="$__image" \
          --label org.label-schema.schema-version="$__dockerfile_version" \
          --no-cache \
          --platform linux/arm/v7,linux/arm64/v8,linux/amd64  .
   __return=$?

   _func_end "$__return" ; return "$__return"
}

#
# usage: _get_image_version --docker_file file ($1) --target local/dockerhub ($2) --distrib debian/alpine ($3)
#
_get_image_version () {
    _func_start

    if _notexist "$1"; then _error "DOCKER_FILE EMPTY"; _func_end "1" ; return 1 ; fi
    if _filenotexist "$1"; then _error "DOCKER_FILE does not exist"; _func_end "1" ; return 1 ; fi
    if _notexist "$2"; then _error "TARGET EMPTY"; _func_end "1" ; return 1 ; fi
    if _notexist "$3"; then _error "DISTRIB EMPTY"; _func_end "1" ; return 1 ; fi

    _debug "DOCKER_FILE:$1"
    _debug "TARGET:$2"
    _debug "DISTRIB:$3"

    local __image
    local __token

    __image=$(echo "$1" | cut -d. -f1 | cut -d/ -f2)

    _debug "image:$__image"

    case "$3" in
        debian|alpine) true;;
        *) _error "distrib must be debian or alpine"; _func_end "1" ; return 1 ;;
    esac

    case "$2" in
        "local")
            __url="http://$LOCAL_REGISTRY"
            __token=""
            __header="Accept: application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.docker.distribution.manifest.v2+json"
            ;;
        "dockerhub")
            if _notexist "$DOCKER_USERNAME"; then _error "DOCKER_USERNAME EMPTY"; _func_end "1" ; return 1 ; fi
            __url="https://registry-1.docker.io"
            __image="$DOCKER_USERNAME/$__image"
            __token=$(_curl "GET" "https://auth.docker.io/token?service=registry.docker.io&scope=repository:$__image:pull" | jq -r '.token')
            __header="Accept: application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.docker.distribution.manifest.v2+json"
            ;;
        *) _error "target must be local or dockerhub"; _func_end "1" ; return 1 ;;
    esac

    _debug "url:$__url"

    for __manifest in $(_curl "GET" "$__url/v2/$__image/manifests/$3" "$__header" "Authorization: Bearer $__token" | jq .manifests | jq -r .[].digest)
    do
        for __digest in $(_curl "GET" "$__url/v2/$__image/manifests/$__manifest" "$__header" "Authorization: Bearer $__token" | jq .config | jq -r .digest)
        do
            __resp=$(_curl "GET" "$__url/v2/$__image/blobs/$__digest" "$__header" "Authorization: Bearer $__token")
            echo "$__resp" | jq -r .config.Labels | $GREP "version"
        done
    done | sort -u | cut -d: -f2 | cut -d\" -f2

    _func_end "0" ; return 0
}

#
# usage: _build_all --target local/dockerhub ($1) --force true/false ($2)
#
_build_all () {
    _func_start

    if _workingdir_isnot "$MY_GIT_DIR/docker" ; then _error "running _build_all outside of $MY_GIT_DIR/docker is not supported"; _func_end "1" ; return 1 ; fi

    if _notexist "$1"; then _error "TARGET EMPTY"; _func_end "1" ; return 1 ; fi
    if _notinstalled "docker"; then _error "docker not found"; _func_end "1" ; return 1 ; fi

    case "$1" in
        "local") true ;;
        "dockerhub")
            if _notexist "$DOCKER_USERNAME"; then _error "DOCKER_USERNAME EMPTY"; _func_end "1" ; return 1 ; fi
            if _notexist "$DOCKER_PASSWORD"; then _error "DOCKER_PASSWORD EMPTY"; _func_end "1" ; return 1 ; fi
            ;;
        *) _error "target must be local or dockerhub"; _func_end "1" ; return 1 ;;
    esac

    local __file
    local __distrib
    local __force
    local __return

    if _notexist "$2"; then __force=false ; else __force="$2" ; fi

    for __file in dockerfile/*; do
        for __distrib in "debian" "alpine"; do
            case $__file in
                *debug*) true;;
                *) _verbose "Building file:$__file"
                   if ! _build "$__file" "$1" "$__distrib" "$__force" ; then _error "something went wrong with build, exiting" ; _func_end "1" ; return 1 ; fi
                   ;;
            esac
        done
    done

    _func_end "0" ; return 0
}

####################################################################################################
############################################# PROCESS ##############################################
####################################################################################################
_process_lib_docker () {
    _func_start

    if ! _load_conf "$MY_GIT_DIR/docker/conf/docker.conf"; then _error "something went wrong when loading docker conf" ; _usage ; _func_end "1" ; return 1 ; fi

    _debug "HTTP_PROXY:$HTTP_PROXY"
    _debug "HTTPS_PROXY:$HTTPS_PROXY"
    _debug "LOCAL_REGISTRY:$LOCAL_REGISTRY"

    eval set -- "$@"

    local __container_name
    local __network_name
    local __volume_name
    local __driver
    local __subnet
    local __gateway
    local __docker_file
    local __target
    local __distrib
    local __force
    local __cmd
    local __return

    while true ; do
        case "$1" in
            --container_name ) __container_name=$2    ; shift ; shift         ;;
            --network_name )   __network_name=$2      ; shift ; shift         ;;
            --volume_name )    __volume_name=$2       ; shift ; shift         ;;
            --driver )         __driver=$2            ; shift ; shift         ;;
            --subnet )         __subnet=$2            ; shift ; shift         ;;
            --gateway )        __gateway=$2           ; shift ; shift         ;;
            --docker_file )    __docker_file=$2       ; shift ; shift         ;;
            --target )         __target=$2            ; shift ; shift         ;;
            --distrib )        __distrib=$2           ; shift ; shift         ;;
            --force )          __force=$2             ; shift ; shift         ;;
            --cmd )            __cmd=$2               ; shift ; shift         ;;
            -- )                                        shift ;         break ;;
            * )                                         shift                 ;;
        esac
    done

    while true ; do
        case "$1" in
            install )                             _install_docker                                                                               ; __return=$? ; break ;;
            compose_file_from_running_container ) _compose_file_from_running_container   "$__container_name"                                    ; __return=$? ; break ;;
            network_list )                        _network_list                                                                                 ; __return=$? ; break ;;
            network_create )	                  _network_create                        "$__network_name" "$__driver" "$__subnet" "$__gateway" ; __return=$? ; break ;;
            volume_list )	                  _volume_list                                                                                  ; __return=$? ; break ;;
            volume_create )	                  _volume_create                         "$__volume_name"                                       ; __return=$? ; break ;;
            volume_remove )	                  _volume_remove                         "$__volume_name"                                       ; __return=$? ; break ;;
            volume_get_mount_point)               _volume_get_mount_point                "$__volume_name"                                       ; __return=$? ; break ;;
            network_remove )	                  _network_remove                        "$__network_name"                                      ; __return=$? ; break ;;
            container_filelog_show )              _container_filelog_show                                                                       ; __return=$? ; break ;;
            container_filelog_truncate )          _container_filelog_truncate                                                                   ; __return=$? ; break ;;
            container_log_show )                  _container_log_show                    "$__container_name"                                    ; __return=$? ; break ;;
            container_list )	                  _container_list                                                                               ; __return=$? ; break ;;
            container_list_verbose )	          _container_list_verbose                                                                       ; __return=$? ; break ;;
            system_df )	                          _system_df                                                                                    ; __return=$? ; break ;;
            system_reclaim )	                  _system_reclaim                                                                               ; __return=$? ; break ;;
            get_image_version)	                  _get_image_version                     "$__docker_file" "$__target" "$__distrib"              ; __return=$? ; break ;;
            build)	                          _build                                 "$__docker_file" "$__target" "$__distrib" "$__force"   ; __return=$? ; break ;;
            container_start)	                  _container_start                       "$__docker_file" "$__target" "$__distrib"              ; __return=$? ; break ;;
            container_stop)	                  _container_stop                        "$__docker_file"                                       ; __return=$? ; break ;;
            container_rshell)	                  _container_rshell                      "$__docker_file" "$__cmd"                              ; __return=$? ; break ;;
            container_shell)	                  _container_shell                       "$__docker_file" "$__target" "$__distrib" "$__cmd"     ; __return=$? ; break ;;
            container_get_ip)	                  _container_get_ip                      "$__container_name" "$__network_name"                  ; __return=$? ; break ;;
            container_get_network_ip)	          _container_get_network_ip              "$__container_name"                                    ; __return=$? ; break ;;
            container_get_network)	          _container_get_network                 "$__container_name"                                    ; __return=$? ; break ;;
            container_connect_to_network)         _container_connect_to_network          "$__container_name" "$__network_name"                  ; __return=$? ; break ;;
            build_all)	                          _build_all                             "$__target" "$__force"                                 ; __return=$? ; break ;;
            -- ) shift ;;
            *) _error "command $1 not found" ; __return=1 ; break ;;
        esac
    done

    _func_end "$__return" ; return "$__return"
}
