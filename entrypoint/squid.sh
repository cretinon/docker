#!/bin/sh

if [ ! -e /squid/squid.pem ]; then
    cd /squid/ || return 1
    openssl req -new -newkey rsa:2048 -sha256 -days 3650 -nodes -x509 -extensions v3_ca -keyout squid.pem -out squid.pem -subj "/C=FR/ST=Paris/L=Paris/O=Global Security/OU=IT Department/CN=example.com"
    openssl x509 -in squid.pem -outform DER -out squid.der
    cd - || return 1
fi

if [ "a$1" = "a" ]; then
    /opt/squid/sbin/squid -z -f /opt/squid/squid.conf
    rm -rf /opt/squid/var/lib/
    mkdir -p /opt/squid/var/lib
    ln -s /opt/squid/libexec/security_file_certgen /opt/squid/libexec/ssl_crtd
    /opt/squid/libexec/ssl_crtd -c -s /opt/squid/var/lib/ssl_db -M 4MB
    chown -R squid:squid /opt/squid/
    /opt/squid/sbin/squid -NF -f /opt/squid/squid.conf
fi
