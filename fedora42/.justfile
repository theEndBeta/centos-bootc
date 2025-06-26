mod bc '../bootc.justfile'

_name := "f42"
_repo := "quay.io/theendbeta"
_repo_local := "localhost:5000"
_tag := "fedora42-bootc"
_version := `date +'%Y%m%d%H%M'`

[private]
default:
  just --list

pull-base:
  podman pull quay.io/fedora/fedora-bootc:42

build tag=_tag version=_version:
  just bc::_build {{ _repo }} {{ tag }} {{ version }}

build-local tag=_tag version=_version:
  just bc::_build {{ _repo_local }} {{ tag }} {{ version }}

push version repo=_repo tag=_tag:
  just bc::_push {{ repo }} {{ tag }} {{ version }}

push-local version repo=_repo_local tag=_tag:
  just bc::_push {{ repo }} {{ tag }} {{ version }}

build-push-local version repo=_repo_local tag=_tag:
  just build-local
  just push-local "{{ version }}"

build-push-gen-local version repo=_repo_local tag=_tag:
  just build-local
  just push-local "{{ version }}"
  just gen-image-local "{{ version }}"

run name=_name tag=_tag repo=_repo:
  just bc::_run {{ name }} {{ tag }} {{ repo }}

run-local name=_name tag=_tag repo=_repo_local:
  just bc::_run {{ name }} {{ tag }} {{ repo }}

exec name=_name:
  podman exec -it {{ name }} /bin/bash

run-it name=_name tag=_tag repo=_repo:
  just bc::_run-it {{ name }} {{ tag }} {{ repo }}

run-it-local name=_name tag=_tag repo=_repo_local:
  just bc::_run-it {{ name }} {{ tag }} {{ repo }}

[private]
_gen-image repo tag version size:
  mkdir -p ./image
  truncate -s {{ size }} "image/{{ _name }}.{{ version }}.raw"
  sudo podman run --rm \
    --privileged \
    --pid=host \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v /dev:/dev \
    -v /var/lib/containers:/var/lib/containers \
    -v ./:/target \
    "{{ repo }}/{{ tag }}:{{ version }}" bootc install to-disk \
    --filesystem=btrfs \
    --generic-image \
    --via-loopback \
    --root-ssh-authorized-keys=/target/authorized_keys \
    "/target/image/{{ _name }}.{{ version }}.raw"

gen-image version tag=_tag size="5G":
  just _gen-image {{ _repo }} {{ tag }} {{ version }} {{ size }}

gen-image-local version tag=_tag size="5G":
  just _gen-image {{ _repo_local }} {{ tag }} {{ version }} {{ size }}

[group("vm")]
vm-launch version="latest" name=_name:
  just bc::vm-launch "fedora-unknown" {{ version }} {{ name }}

[group("vm")]
vm-start version="latest" name=_name:
  just bc::vm-start {{ version }} {{ name }}

[group("vm")]
vm-stop version="latest" name=_name:
  just bc::vm-stop {{ version }} {{ name }}

[group("vm")]
vm-delete version="latest" name=_name:
  just bc::vm-delete {{ version }} {{ name }}
