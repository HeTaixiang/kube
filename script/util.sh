#!/bin/bash
# Print a status line. Formatted to show up in a stream of output.
kube::log::status() {
  timestamp=$(date +"[%m%d %H:%M:%S]")
  echo "+++ $timestamp $1"
  shift
  for message; do
    echo "    $message"
  done
}

# Log an error and exit
kube::log::fatal() {
  timestamp=$(date +"[%m%d %H:%M:%S]")
  echo "!!! $timestamp ${1-}" >&2
  shift
  for message; do
    echo "    $message" >&2
  done
  exit 1
}

# Get the architecture for the current machine
kube::helpers::host_platform() {
  local host_os
  local host_arch
  case "$(uname -s)" in
    Linux)
      host_os=linux;;
    *)
      kube::log::fatal "Unsupported host OS. Must be linux.";;
  esac

  case "$(uname -m)" in
    x86_64*)
      host_arch=amd64;;
    i?86_64*)
      host_arch=amd64;;
    amd64*)
      host_arch=amd64;;
    aarch64*)
      host_arch=arm64;;
    arm64*)
      host_arch=arm64;;
    arm*)
      host_arch=arm;;
    ppc64le*)
      host_arch=ppc64le;;
    *)
      kube::log::fatal "Unsupported host arch. Must be x86_64, arm, arm64 or ppc64le.";;
  esac
  echo "${host_os}/${host_arch}"
}

kube::helpers::command_exists() {
  command -v "$@" > /dev/null 2>&1
}
