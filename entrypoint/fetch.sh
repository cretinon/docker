#!/bin/sh

# Fetches a URL for a *build* (a release tarball and the like), through the apt cache of the
# lab when one is configured in the HTTP_PROXY build argument, and straight to the internet
# when the cache cannot deliver it.
#
# apt-cacher-ng reads http only: it answers `403 CONNECT tunnel failed` to an https request
# handed to it as a proxy, so an https URL is rewritten with the `HTTPS///` marker its manual
# documents -- `http://<cache>:3142/HTTPS///<host>/<path>` -- which asks the cache to fetch the
# https URL itself and store the body. The proxy variables are blanked for that call: with
# them set, wget would hand the *marked* URL to the cache as a proxy, and the cache refuses a
# request whose target port is not 80 or 443 (`403 … prohibited port`).
#
# **The cache is tried first, the internet second, and only the body decides.** The releases of
# GitHub are served through a signed `release-assets.githubusercontent.com` URL that the cache
# fetches itself: when that transfer dies half-way, the cache stores the part it got and
# replays it as a complete response -- with a `Content-Length` matching the truncation. wget
# then reports a perfectly *saved* file, and the `tar`/`unzip` of the caller is where the
# truncation finally shows up. So the body is buffered, checked (`gzip -t` for a gzip archive,
# `unzip -t` for a zip), and a body that fails is a *failure*: the next attempt then goes
# straight out, where a dropped transfer only costs what it dropped.
#
# The download is **resumed** (`wget -c` into the same file) instead of restarted, because the
# link of the lab is slow and a retry that starts over from zero is what makes a 193 MB asset
# unattainable. A body that came from the cache is dropped before a direct attempt: resuming
# it would splice the part the cache got with the part the internet serves, and two sources
# are not one file.
#
# No timeout is set anywhere (neither `--timeout` here, nor `--max-time` on a probe): the link
# is slow, the cache may stay silent while it pulls the asset from upstream, and aborting a
# transfer that is merely slow is what leaves a truncated file behind.
#
# The body is printed on stdout, so the caller keeps its `> /path/file` (or `| tar xz …`).
#
# usage: fetch.sh <url>
#
# The cache is read from the environment *or* from the build argument of the same name (the
# Dockerfiles clear `ENV HTTP_PROXY` after their apt steps, and pass `HTTP_PROXY="$HTTP_PROXY"`
# to the calls below): `ARG HTTP_PROXY` and `ENV HTTP_PROXY` are two different things.

url="$1"

if [ -z "$url" ]; then
    echo "fetch.sh: URL EMPTY" >&2
    exit 1
fi

cache="$HTTP_PROXY"

# three attempts, the first through the cache, 5 seconds apart: enough to ride out a hiccup of
# the cache or of the link, short enough not to hold a build hostage
attempts=3
delay=5

work="$(mktemp -d)"
body="$work/body"
trap 'rm -rf "$work"' EXIT HUP INT TERM

# __through_cache: one attempt through apt-cacher-ng, into $body
__through_cache() {
    case "$url" in
        https://*)
            # the `HTTPS///` marker of apt-cacher-ng: it fetches the https URL itself
            http_proxy= https_proxy= HTTP_PROXY= HTTPS_PROXY= \
                wget -c --no-verbose --tries=3 -O "$body" "$cache/HTTPS///${url#https://}"
            ;;
        *)
            # an http URL is what the cache already reads: it is fetched through it as a proxy
            wget -c --no-verbose --tries=3 -O "$body" "$url"
            ;;
    esac
}

# __straight_out: one attempt on the internet, the cache left out of the path
__straight_out() {
    http_proxy= https_proxy= HTTP_PROXY= HTTPS_PROXY= \
        wget -c --no-verbose --tries=3 -O "$body" "$url"
}

# __complete: does $body hold a whole archive of its kind? An unreadable or truncated body
# returns non-zero, and a body that is not an archive this function knows is taken as it is.
# The tool is kept quiet: the verdict is what fetch.sh prints, not `gzip: ... not in gzip
# format` lost in the log of a build
__complete() {
    case "$url" in
        *.tar.gz|*.tgz|*.gz)
            gzip -t "$body" >/dev/null 2>&1
            ;;
        *.zip)
            if command -v unzip >/dev/null 2>&1 ; then unzip -tq "$body" >/dev/null 2>&1 ; else return 0 ; fi
            ;;
        *)
            return 0
            ;;
    esac
}

attempt=1
origin=""
reason=""

while : ; do
    failed=""

    if [ "$attempt" -eq 1 ] && [ -n "$cache" ]; then
        wanted="cache"
    else
        wanted="direct"
    fi

    if [ "$wanted" = "direct" ] && [ "$origin" != "direct" ]; then
        rm -f "$body"
        if [ "$attempt" -gt 1 ]; then
            echo "fetch.sh: the cache did not deliver $url, going straight out" >&2
        fi
    fi
    origin="$wanted"

    if [ "$wanted" = "cache" ]; then
        __through_cache || failed="true"
    else
        __straight_out || failed="true"
    fi

    reason="wget failed for $url"

    if [ -z "$failed" ]; then
        if [ ! -s "$body" ]; then
            failed="true"
            reason="empty body for $url"
        elif ! __complete ; then
            failed="true"
            reason="incomplete archive for $url"
        fi
    fi

    if [ -z "$failed" ]; then
        cat "$body"
        break
    fi

    if [ "$attempt" -ge "$attempts" ]; then
        echo "fetch.sh: $reason" >&2
        exit 1
    fi

    attempt=$((attempt + 1))
    echo "fetch.sh: retrying $url (attempt $attempt/$attempts)" >&2
    sleep "$delay"
done
