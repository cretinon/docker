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

    if ! _func_exist "_playbook_localhost_docker" ; then _error "lib_ansible not installed" ; _func_end ; return 1 ; fi

    _playbook_localhost_docker

    _func_end
}

####################################################################################################
########################################### DOCKER ADMIN ###########################################
####################################################################################################
#
# usage: _volume_create --volume_name name ($1)
#
_volume_create () {
    _func_start

    if _notexist "$1"; then _error "volume_name empty"; _func_end ; return 1 ; fi

    _debug "volume_name:$1"

    if docker volume ls | $GREP "$1" > /dev/nulll; then
        _warning "volume already exist"
    else
        docker volume create "$1"
    fi

    _func_end
}

#
# usage: _volume_list
#
_volume_list () {
    _func_start

    docker volume ls | awk '{print $2}' | $GREP -vw "VOLUME"

    _func_end
}

#
# usage: _volume_remove --volume_name name ($1)
#
_volume_remove () {
    _func_start

    if _notexist "$1"; then _error "volume_name empty"; _func_end ; return 1 ; fi

    _debug "volume_name:$1"

    if docker volume ls | $GREP "$1" > /dev/nulll; then
        docker volume remove "$1"
    else
        _warning "volume doesnt exist"
    fi

    _func_end
}

#
# usage: _network_create --network_name name ($1) --driver driver ($2) --subnet 172.xx.0.0/16 ($3) --gateway 172.xx.xxx.xxx ($4)
#
_network_create () {
    _func_start

    if _notexist "$1"; then _error "network_name EMPTY"; _func_end ; return 1 ; fi
    if _notexist "$2"; then _error "driver EMPTY (must be in:bridge, overlay, host, null)"; _func_end ; return 1 ; fi
    if _notexist "$3"; then _error "subnet EMPTY"; _func_end ; return 1 ; fi
    if _notexist "$4"; then _error "gateway EMPTY"; _func_end ; return 1 ; fi

    _debug "network_name:$1"
    _debug "driver:$2"
    _debug "subnet:$3"
    _debug "gateway:$4"

    if _network_list | $GREP -w "$1" > /dev/null; then
        _warning "network already exist"
    else
        docker network create -d "$2" --subnet="$3" --gateway="$4" "$1"
    fi

    _func_end
}

#
# usage: _network_list
#
_network_list () {
    _func_start

    docker network list | awk '{print $2}' | $GREP -vw ID

    _func_end
}

#
# usage: _network_remove --network_name name ($1)
#
_network_remove () {
    _func_start

    if _notexist "$1"; then _error "network_name EMPTY";_func_end ; return 1 ; fi

    _debug "network_name:$1"

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

    if _notexist "$1"; then _error "container_name EMPTY ('main --docker container_list' to list active containers)"; _func_end ; return 1 ; fi

    _debug "container_name:$1"

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

####################################################################################################
############################################ CONTAINER #############################################
####################################################################################################
#
# usage: _compose_file_from_running_container --container_name name ($1)
#
_compose_file_from_running_container () {
    _func_start

    if _notexist "$1"; then _error "container_name EMPTY"; _func_end ; return 1 ; fi

    _debug "container_name:$1"

    echo ""
    echo "####"
    echo "paste it to https://www.composerize.com/"
    echo "####"
    echo ""

    docker run --rm -ti -v /var/run/docker.sock:/var/run/docker.sock bcicen/docker-replay -p "$1"

    _func_end
}

####################################################################################################
############################################## IMAGES ##############################################
####################################################################################################
#
# _make_action action ($1) docker_file ($2)
#
_make_action () {
    _func_start

    if _notexist "$2"; then _error "docker_file EMPTY"; _func_end ; return 1 ; fi
    if _filenotexist "$2"; then _error "docker_file does not exist"; _func_end ; return 1 ; fi
    if _workingdir_isnot "$MY_GIT_DIR/docker"; then _error "running make_build outside of $MY_GIT_DIR/docker is not supported"; _func_end ; return 1 ; fi

    _debug "docker_file:$2"
    _debug "docker_file exist:$2"


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
                if ! make "$1" ARCH="$__arch" DISTRIB="$__distrib" OPSYS="$__opsys" SVCNAME="$__svcname"; then
                    _error "'make $1 ARCH=$__arch DISTRIB=$__distrib OPSYS=$__opsys SVCNAME=$__svcname' goes wrong, stop here" ; _func_end ; return 1
                fi
                ;;
            *)
                    _error "Action $1 not defined" ; _func_end ; return 1
                    ;;
        esac
    else
        case $1 in
            build|push|shell|rshell|start|stop)
                if ! make "$1" ARCH="$__arch" DISTRIB="$__distrib" OPSYS="$__opsys" SVCNAME="$__svcname" 1>/dev/null 2>/dev/null; then
                    _error "'make $1 ARCH=$__arch DISTRIB=$__distrib OPSYS=$__opsys SVCNAME=$__svcname' goes wrong, run again with -v" ; _func_end ; return 1
                fi
                ;;
            *)
                _error "Action $1 not defined" ; _func_end ; return 1
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
# usage: _build --docker_file file ($1) --target local/dockerhub ($2) --distrib debian/alpine ($3) --force true/false ($4)
#
_build () {
    _func_start

    if _notexist "$1"; then _error "DOCKER_FILE EMPTY"; _func_end ; return 1 ; fi
    if _filenotexist "$1"; then _error "DOCKER_FILE:$1 does not exist"; _func_end ; return 1 ; fi
    if _notexist "$2"; then _error "TARGET EMPTY"; _func_end ; return 1 ; fi
    if _notexist "$3"; then _error "DISTRIB EMPTY"; _func_end ; return 1 ; fi

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

    __image=$(echo "$1" | cut -d. -f1 | cut -d/ -f2)
    __opsys=$(echo "$__image" | cut -d_ -f1 | cut -d/ -f2)
    __dockerfile_version=$($GREP "ARG VERSION=" "$1" | cut -d\" -f2)
    if ! __image_version=$(_get_image_version "$1" "$2" "$3") ; then _error "something went wrong with get_image_version" ; _func_end ; return 1  ; fi

    if _notexist "$__dockerfile_version"; then _error "No version in $1"; _func_end ; return 1 ; fi

    if _notexist "$4"; then __force=false ; else __force="$4" ; fi

    if [ "a$__image_version" = "a$__dockerfile_version" ]; then
        if [ "a$__force" != "atrue" ]; then
            _warning "trying to build same version as existing in $2 repository. Skipping."
            _func_end
            return 0
        else
            _verbose "trying to build same version as existing in $2 repository. But FORCE."
        fi
    fi

    _debug "image:$__image"
    _debug "opsys:$__opsys"

    case "$2" in
        "local")
            __target="docker.intranet.local:5000" ;
            __http_proxy="http://192.168.2.28:3142" ;
            __https_proxy="http://192.168.2.28:3142" ;
            __output_build="type=registry"",registry.insecure=true"
            ;;
       "dockerhub")
           if _notexist "$DOCKER_USERNAME"; then _error "DOCKER_USERNAME EMPTY"; _func_end ; return 1 ; fi
           docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"
           __target="$DOCKER_USERNAME"
           __http_proxy=""
           __https_proxy=""
           __output_build="type=registry,registry.insecure=false"
           ;;
        *) _error "bad target $2 (must be local/dockerhub)"; _func_end ; return 1 ;;
    esac

    case "$3" in
        "debian")
            __base_tag="stable-slim"
            ;;
        "alpine")
            __base_tag="3.22"
            ;;
        *)_error "bad distrib $3 (must be debian/alpine)"; _func_end ; return 1 ;;
    esac

    _debug "Going to build=>""$__target"/"$__image":"$3"

    #creating buildkit conf file, even if we're in CI
    sudo mkdir -p /etc/buildkit/
    sudo cat <<EOF | sudo tee /etc/buildkit/buildkitd.toml
debug = true
trace = true
insecure-entitlements = [ "network.host", "security.insecure", "device" ]

[log]
  format = "text"

[registry."docker.intranet.local:5000"]
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

    _func_end
}

#
# usage: _get_image_version --docker_file file ($1) --target local/dockerhub ($2) --distrib debian/alpine ($3)
#
_get_image_version () {
    _func_start

    if _notexist "$1"; then _error "DOCKER_FILE EMPTY"; _func_end ; return 1 ; fi
    if _filenotexist "$1"; then _error "DOCKER_FILE does not exist"; _func_end ; return 1 ; fi
    if _notexist "$2"; then _error "TARGET EMPTY"; _func_end ; return 1 ; fi
    if _notexist "$3"; then _error "DISTRIB EMPTY"; _func_end ; return 1 ; fi

    _debug "DOCKER_FILE:$1"
    _debug "TARGET:$2"
    _debug "DISTRIB:$3"

    local __image
    local __token

    __image=$(echo "$1" | cut -d. -f1 | cut -d/ -f2)

    _debug "image:$__image"

    case "$3" in
        debian|alpine) true;;
        *) _error "distrib must be debian or alpine"; _func_end ; return 1 ;;
    esac

    case "$2" in
        "local")
            __url="http://docker.intranet.local:5000"
            __token=""
            __header="Accept: application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.docker.distribution.manifest.v2+json"
            ;;
        "dockerhub")
            if _notexist "$DOCKER_USERNAME"; then _error "DOCKER_USERNAME EMPTY"; _func_end ; return 1 ; fi
            __url="https://registry-1.docker.io"
            __image="$DOCKER_USERNAME/$__image"
            __token=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:$__image:pull" | jq -r '.token')
            __header="Accept: application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.docker.distribution.manifest.v2+json"
            ;;
        *) _error "target must be local or dockerhub"; _func_end ; return 1 ;;
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
}

#
# usage: _build_all --target local/dockerhub ($1) --force true/false ($2)
#
_build_all () {
    _func_start

    if _workingdir_isnot "$MY_GIT_DIR/docker" ; then _error "running _build_all outside of $MY_GIT_DIR/docker is not supported"; _func_end; return 1 ; fi

    if _notexist "$1"; then _error "TARGET EMPTY"; _func_end ; return 1 ; fi

    case "$1" in
        "local") true ;;
        "dockerhub")
            if _notexist "$DOCKER_USERNAME"; then _error "DOCKER_USERNAME EMPTY"; _func_end ; return 1 ; fi
            if _notexist "$DOCKER_PASSWORD"; then _error "DOCKER_PASSWORD EMPTY"; _func_end ; return 1 ; fi
            ;;
        *) _error "target must be local or dockerhub"; _func_end ; return 1 ;;
    esac

    local __file
    local __distrib
    local __force

    if _notexist "$2"; then __force=false ; else __force="$2" ; fi

    for __file in dockerfile/*; do
        for __distrib in "debian" "alpine"; do
            case $__file in
                *debug*) true;;
                *) _verbose "Building file:$__file"
                   _build "$__file" "$1" "$__distrib" "$__force"
                   ;;
            esac
        done
    done

    _func_end
}

####################################################################################################
############################################# PROCESS ##############################################
####################################################################################################
_process_lib_docker () {
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
            -- )                                        shift ;         break ;;
            * )                                         shift                 ;;
        esac
    done

    while true ; do
        case "$1" in
            install )                             _install_docker                                                                               ; return $? ;;
            compose_file_from_running_container ) _compose_file_from_running_container   "$__container_name"                                    ; return $? ;;
            network_list )                        _network_list                                                                                 ; return $? ;;
            network_create )	                  _network_create                        "$__network_name" "$__driver" "$__subnet" "$__gateway" ; return $? ;;
            volume_list )	                  _volume_list                                                                                  ; return $? ;;
            volume_create )	                  _volume_create                         "$__volume_name"                                       ; return $? ;;
            volume_remove )	                  _volume_remove                         "$__volume_name"                                       ; return $? ;;
            network_remove )	                  _network_remove                        "$__network_name"                                      ; return $? ;;
            container_filelog_show )              _container_filelog_show                                                                       ; return $? ;;
            container_filelog_truncate )          _container_filelog_truncate                                                                   ; return $? ;;
            container_log_show )                  _container_log_show                    "$__container_name"                                    ; return $? ;;
            container_list )	                  _container_list                                                                               ; return $? ;;
            system_df )	                          _system_df                                                                                    ; return $? ;;
            system_reclaim )	                  _system_reclaim                                                                               ; return $? ;;
            get_image_version)	                  _get_image_version                     "$__docker_file" "$__target" "$__distrib"              ; return $? ;;
            build)	                          _build                                 "$__docker_file" "$__target" "$__distrib" "$__force"   ; return $? ;;
            build_all)	                          _build_all                             "$__target" "$__force"                                 ; return $? ;;
            make_shell)	                          _make_shell                            "$__docker_file"                                       ; return $? ;;
            make_rshell)                          _make_rshell                           "$__docker_file"                                       ; return $? ;;
            make_start)	                          _make_start                            "$__docker_file"                                       ; return $? ;;
            make_stop)	                          _make_stop                             "$__docker_file"                                       ; return $? ;;
            -- ) shift ;;
            *) if [ "a$1" != "a" ]; then return 1 ;  else break; fi ;;
        esac
    done
}
