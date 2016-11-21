#!/bin/bash
# Copyright 2016 Google Inc. All Rights Reserved.
# Author: cheesy@google.com (Steve Hill)
#
# Install packages required for building mod_pagespeed.

if [ "$UID" -ne 0 ]; then
  echo Root is required to run this. Re-execing with sudo
  exec sudo $0 "$@"
  exit 1  # NOTREACHED
fi

additional_test_packages=false
if [ "${1:-}" = "--additional_test_packages" ]; then
  additional_test_packages=true
  shift
fi

if [ $# -ne 0 ]; then
  echo "Usage: $(basename $0) [--additional_test_packages]" >&2
  exit 1
fi

binary_packages=(subversion apache2 g++ gperf devscripts fakeroot git-core
  zlib1g-dev wget curl net-tools rsync ssl-cert psmisc)
src_packages=()

if version_compare $(lsb_release -rs) -lt 14.04; then
  binary_packages+=(gcc-mozilla)
fi

install_redis_from_src=false
if "$additional_test_packages"; then
  binary_packages+=(memcached libapache2-mod-php5 autoconf valgrind libev-dev
    libssl-dev libpcre3-dev)

  if version_compare $(lsb_release -sr) -ge 16.04; then
    binary_packages+=(redis-server)
  else
    src_packages+=(redis-server)
  fi

  if [ -n "$(apt-cache search --names-only '^libtool-bin$')" ]; then
    # With Ubuntu 16+ we need libtool-bin instead.
    binary_packages+=("libtool-bin")
  else
    binary_packages+=("libtool")
  fi
fi

apt-get -y install "${binary_packages[@]}"
install_from_src "${src_packages[@]}"
