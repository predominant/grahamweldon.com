#!/bin/sh

SKIPBUILD=${SKIPBUILD:-0}

hab pkg install --binlink core/bats

hab pkg install core/busybox-static
hab pkg binlink core/busybox-static ps
hab pkg binlink core/busybox-static netstat
hab pkg binlink core/busybox-static wc
hab pkg binlink core/busybox-static uniq

source ./plan.sh

if [ "${SKIPBUILD}" -eq 0 ]; then
  set -e
  build
  source results/last_build.env
  hab pkg install --binlink --force "results/${pkg_artifact}"
  hab svc load "${pkg_ident}"
  set +e

  # Give some time for the service to start up
  sleep 5
fi

bats test.bats
