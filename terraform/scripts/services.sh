#!/bin/sh

hab svc load \
  grahamweldon/site-grahamweldon \
  --strategy at-once

hab svc load \
  grahamweldon/site-loadbalancer \
  --strategy at-once \
  --bind grahamweldon:site-grahamweldon.default