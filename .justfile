name := "c10"
repo := "quay.io/theendbeta"
tag := "centos10-bootc"
version := `date +'%Y%m%d%H%M'`

[private]
default:
  just --list

pull-base:
  podman pull quay.io/centos-bootc/centos-bootc:stream10

build tag=tag ver=version:
  podman build . -f Containerfile \
    -t "{{ tag }}" \
    -t "{{repo}}/{{ tag }}:{{ version }}" \
    -t "{{repo}}/{{ tag }}:latest"

run name=name tag=tag:
  podman run --detach --replace --name {{ name }} "{{ repo }}/{{ tag }}"

exec name=name:
  podman exec -it {{ name }} /bin/bash

run-it name=name tag=tag:
 podman run --rm -it "{{ repo }}/{{ tag }}" /bin/bash

gen-image size="4G":
  mkdir -p ./image
  truncate -s {{ size }} "image/{{ tag }}.{{ version }}.raw"
  sudo podman run --rm \
    --privileged \
    --pid=host \
    --security-opt label=type:unconfined_t \
    -v /dev:/dev \
    -v /var/lib/containers:/var/lib/containers \
    -v .:/output \
    "{{ repo }}/{{ tag }}" bootc install to-disk \
    --generic-image \
    --via-loopback \
    "/output/image/{{ tag }}.{{ version }}.raw"
