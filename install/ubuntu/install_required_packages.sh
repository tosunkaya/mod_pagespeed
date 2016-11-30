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

additional_dev_packages=false
if [ "${1:-}" = "--additional_dev_packages" ]; then
  additional_dev_packages=true
  shift
fi

if [ $# -ne 0 ]; then
  echo "Usage: $(basename $0) [--additional_dev_packages]" >&2
  exit 1
fi

binary_packages=(subversion apache2 g++ gperf devscripts fakeroot git-core
  zlib1g-dev wget curl net-tools rsync ssl-cert psmisc)
src_packages=()

if version_compare $(lsb_release -rs) -lt 14.04; then
  binary_packages+=(gcc-mozilla)
fi

# Sometimes the names of packages change between versions.  This goes through
# its arguments and returns the first package name that exists on this OS.
function first_available_package() {
  for candidate_version in "$@"; do
    if [ -n "$(apt-cache search --names-only "^${candidate_version}$")" ]; then
      echo "$candidate_version"
      return
    fi
  done
  echo "error: no available version of $@" >&2
  exit 1
}

install_redis_from_src=false
if "$additional_dev_packages"; then
  binary_packages+=(memcached autoconf valgrind libev-dev libssl-dev
    libpcre3-dev openjdk-7-jre language-pack-tr-base gperf)

  if version_compare $(lsb_release -sr) -ge 16.04; then
    binary_packages+=(redis-server)
  else
    src_packages+=(redis-server)
  fi

  binary_packages+=( \
    $(first_available_package libtool-bin libtool)
    $(first_available_package php-cgi php5-cgi)
    $(first_available_package libapache2-mod-php libapache2-mod-php5)
    $(first_available_package php-mbstring libapache2-mod-php5))
fi

apt-get -y install "${binary_packages[@]}"
if [ ${#src_packages[@]} -gt 0 ]; then
  install_from_src "${src_packages[@]}"
fi
