#!/bin/bash

# Common setup for all Jenkins scripts
# shellcheck source=./common_utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/common_utils.sh"
set -ex

# Required environment variables:
#   $BUILD_ENVIRONMENT (should be set by your Docker image)

# Figure out which Python to use for ROCm
if [[ "${BUILD_ENVIRONMENT}" == *rocm* ]]; then
  # HIP_PLATFORM is auto-detected by hipcc; unset to avoid build errors
  unset HIP_PLATFORM
  export PYTORCH_TEST_WITH_ROCM=1
  # temporary to locate some kernel issues on the CI nodes
  export HSAKMT_DEBUG_LEVEL=4
  # improve rccl performance for distributed tests
  export HSA_FORCE_FINE_GRAIN_PCIE=1
  # CI=1 is required for test infra code to dump the XML files
  # and for few test files having custom test hander
  # https://ontrack-internal.amd.com/browse/SWDEV-386400
  export CI=1
fi

# This token is used by a parser on Jenkins logs for determining
# if a failure is a legitimate problem, or a problem with the build
# system; to find out more, grep for this string in ossci-job-dsl.
echo "ENTERED_USER_LAND"

trap_add cleanup EXIT

# TODO: Renable libtorch testing for MacOS, see https://github.com/pytorch/pytorch/issues/62598
# shellcheck disable=SC2034
BUILD_TEST_LIBTORCH=0

# TODO: Reenable nvfuser when issues with gfx908 resolved
PYTORCH_JIT_ENABLE_NVFUSER=0

retry () {
  "$@"  || (sleep 1 && "$@") || (sleep 2 && "$@")
}
