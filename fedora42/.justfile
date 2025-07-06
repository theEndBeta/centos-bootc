mod bc '../bootc.justfile'

_name := "f42"
_repo := "quay.io/theendbeta"
_repo_local := "localhost:5000"
_tag := "fedora-bootc"
_base_version := "42"
_version := _base_version + "-" + `date +'%Y%m%d%H%M'`
_v_latest := _base_version + "-latest"

[private]
default:
  just --list

[group("container")]
pull-base:
  podman pull quay.io/fedora/fedora-bootc:{{ _base_version }}

[group("container")]
build version=_version repo=_repo tag=_tag:
  podman build . --pull=newer -f Containerfile \
    -t "{{ repo }}/{{ tag }}:{{ version }}" \
    -t "{{ repo }}/{{ tag }}:{{ _v_latest }}"

# Build image tags 
[group("container")]
build-local  version=_v_latest tag=_tag:
  podman build . --pull=newer -f Containerfile \
    -t "{{ _repo_local }}/{{ tag }}:{{ version }}"

# Push <tag> to local <repo>
[group("container")]
push version repo=_repo tag=_tag:
  just bc::_push {{ repo }} {{ tag }} {{ version }}

# Push <tag> to local <repo>
[group("container")]
push-local version=_v_latest repo=_repo_local tag=_tag:
  just bc::_push {{ repo }} {{ tag }} {{ version }}

# Build the base image and push to local repo
[group("container")]
build-push-local version=_v_latest repo=_repo_local tag=_tag:
  just build-local "{{ version }}"
  just push-local "{{ version }}"

[group("container")]
[group("cloud")]
build-push-cloud version=_version repo=_repo tag=_tag:
  just build {{ version }} {{ repo }} {{ tag }}
  just push {{ version }} {{ repo }} {{ tag }}
  just push {{ _v_latest }} {{ repo }} {{ tag }}

# Build the base image, push to local repo, and generate the disk image
[group("container")]
[group("disk-image")]
build-push-gen-local version=_v_latest repo=_repo_local tag=_tag:
  just build-local "{{ version }}"
  just push-local "{{ version }}"
  just gen-image-local "{{ version }}"

[group("container")]
run name=_name tag=_tag repo=_repo:
  just bc::_run {{ name }} {{ tag }} {{ repo }}

[group("container")]
run-local name=_name tag=_tag repo=_repo_local:
  just bc::_run {{ name }} {{ tag }} {{ repo }}

[group("container")]
exec name=_name:
  podman exec -it {{ name }} /bin/bash

[group("container")]
run-it version=_v_latest name=_name tag=_tag repo=_repo:
  just bc::_run-it {{ version }} {{ name }} {{ tag }} {{ repo }}

[group("container")]
run-it-local version=_v_latest name=_name tag=_tag repo=_repo_local:
  just bc::_run-it {{ version }} {{ name }} {{ tag }} {{ repo }}

[private]
[group("disk-image")]
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
    --generic-image \
    --via-loopback \
    --root-ssh-authorized-keys=/target/authorized_keys \
    --filesystem=btrfs \
    "/target/image/{{ _name }}.{{ version }}.raw"

[group("disk-image")]
gen-cloud-image repo=_repo tag=_tag size="4G":
  just build
  just push "{{ _v_latest }}"
  just push "{{ _version }}"

  mkdir -p ./image
  truncate -s {{ size }} "image/{{ _name }}.{{ _v_latest }}.img"
  sudo podman run --rm \
    --privileged \
    --pid=host \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v /dev:/dev \
    -v /var/lib/containers:/var/lib/containers \
    -v ./:/target \
    "{{ _repo }}/{{ tag }}:{{ _v_latest }}" bootc install to-disk \
    --generic-image \
    --via-loopback \
    --filesystem=btrfs \
    "/target/image/{{ _name }}.{{ _v_latest }}.img"
  gzip "image/{{ _name }}.{{ _v_latest }}.img"

[group("disk-image")]
gen-image version tag=_tag size="4G":
  just _gen-image {{ _repo }} {{ tag }} {{ version }} {{ size }}

[group("disk-image")]
gen-image-local version=_v_latest tag=_tag size="10G":
  just _gen-image {{ _repo_local }} {{ tag }} {{ version }} {{ size }}

[group("vm")]
vm-launch version=_v_latest name=_name:
  just bc::vm-launch "fedora-unknown" {{ version }} {{ name }}

[group("vm")]
vm-start version=_v_latest name=_name:
  just bc::vm-start {{ version }} {{ name }}

[group("vm")]
vm-stop version=_v_latest name=_name:
  just bc::vm-stop {{ version }} {{ name }}

[group("vm")]
vm-delete version=_v_latest name=_name:
  just bc::vm-delete {{ version }} {{ name }}
