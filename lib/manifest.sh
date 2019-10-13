#!/bin/bash
set -eou pipefail

# shellcheck source=functions.sh source=lib/functions.sh disable=SC1091
source "$(dirname "$(realpath -s "$0")")/functions.sh"

if [[ $# == 0 ]]; then
  $#="--help"
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    "-h" | "--help")
      echo "Usage:"
      echo "../lib/build.sh [-h|--help] [-b|--binary docker|podman] [-d|--delay N] [--hook URL] [-i|--image supersandro2000/base-alpine|base-alpine] [-p|--push] [--variant amd64|arm64|armhf] [-v|--verbose] [--version 1.0.0|infile]"
      echo "--help      Show this help."
      echo "--binary    Binary which runs the build commands."
      echo "--delay     How many seconds should be waited between pushes."
      echo "--hook      URL to send POST request after sucessful push."
      echo "--image     Image being pushed"
      echo "--push      Push manifest to registry. Manifest variants need to be on the registry already."
      echo "--variant   Variants which should be included seperated by comma. Defaults to amd64,arm64,armhf."
      echo "--verbose   Be more verbose."
      echo
      show_exit_codes
      exit 0
      ;;
    "-b" | "--binary")
      binary="$2"
      shift
      ;;
    "-d" | "--delay")
      delay="$2"
      shift
      ;;
    "-i" | "--image")
      image="$2"
      shift
      ;;
    "--hook")
      hook="$2"
      shift
      ;;
    "-p" | "--push")
      push=true
      ;;
    "--variant")
      variant="$2"
      shift
      ;;
    "--verbose")
      verbose=true
      ;;
    "--version")
      version="$2"
      shift
      ;;
  esac
  shift
done

if [[ -n ${verbose:-} ]]; then
  set -x
fi

if [[ -z ${binary:-} ]]; then
  binary=docker
fi

check_tool "$binary --version" docker
check_tool "curl --version" curl

if [[ -z ${delay:-} ]]; then
  delay=3
elif ! [[ $delay =~ ^[0-9]+$ ]]; then
  echo "$delay is not a number. Delay only takes whole numbers."
  exit 1
fi

if [[ -z ${image:-} ]]; then
  echo "You need to supply --image NAME."
  exit 1
else
  if [[ ! $image =~ "/" ]]; then
    image="supersandro2000/$image"
  fi
fi

if [[ -z ${variant:-} ]]; then
  variant="amd64,arm64,armhf"
fi

if [[ -z ${version:-} ]]; then
  echo "You need to supply --version 1.0.0."
  exit 1
fi

export DOCKER_CLI_EXPERIMENTAL=enabled

for version_latest in $version latest; do
  variant_manifest=""
  image_variant="$image:$version_latest"

  IFS=","
  for arch in $variant; do
    variant_manifest+="$image:$arch-$version_latest "
  done
  IFS=" "

  # remove images that are tagged the same as the manifest being created
  $binary rmi "$image_variant" || true
  rm -rf "$HOME/.docker/manifests/docker.io_${image//\//_}-"*

  #shellcheck disable=SC2068
  $binary manifest create "$image_variant" ${variant_manifest[@]}

  $binary manifest annotate "$image_variant" "$image:amd64-$version_latest" --os linux --arch amd64
  $binary manifest annotate "$image_variant" "$image:armhf-$version_latest" --os linux --arch arm --variant v7
  $binary manifest annotate "$image_variant" "$image:arm64-$version_latest" --os linux --arch arm64 --variant v8

  if [[ -n ${push:-} ]]; then
    retry "$binary manifest push $image_variant"
  fi
  sleep "$delay"
done

if [[ -z $hook ]]; then
  curl -X POST "$hook"
fi
