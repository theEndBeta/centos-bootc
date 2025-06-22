name := "c10"
_repo := "quay.io/theendbeta"
_repo_local := "localhost:5000"
_tag := "centos10-bootc"
_version := `date +'%Y%m%d%H%M'`

[private]
default:
  just --list

pull-base:
  podman pull quay.io/centos-bootc/centos-bootc:stream10

[private]
_build repo tag version:
  podman build . -f Containerfile \
    -t "{{repo}}/{{ tag }}:{{ version }}" \
    -t "{{repo}}/{{ tag }}:latest"

build tag=_tag version=_version: (_build _repo tag version)

build-local tag=_tag version=_version: (_build _repo_local tag version)

[private]
_push repo tag version:
  podman push "{{repo}}/{{ tag }}:{{ version }}"

push version repo=_repo tag=_tag: (_push repo tag version )

push-local version repo=_repo_local tag=_tag: (_push repo tag version)

[private]
_run name tag repo:
  podman run --detach --replace --name {{ name }} "{{ repo }}/{{ tag }}"

run name=name tag=_tag repo=_repo: (_run name tag repo)

run-local name=name tag=_tag repo=_repo_local: (_run name tag repo)

exec name=name:
  podman exec -it {{ name }} /bin/bash

[private]
_run-it name tag repo:
 podman run --rm -it "{{ repo }}/{{ tag }}" /bin/bash

run-it name=name tag=_tag repo=_repo: (_run-it name tag repo)

run-it-local name=name tag=_tag repo=_repo_local: (_run-it name tag repo)

[private]
_gen-image repo tag version size="4G":
  mkdir -p ./image
  truncate -s {{ size }} "image/{{ tag }}.{{ version }}.raw"
  sudo podman run --rm \
    --privileged \
    --pid=host \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v /dev:/dev \
    -v /var/lib/containers:/var/lib/containers \
    -v ./config.toml:/config.toml:ro \
    -v ./:/target \
    "{{ repo }}/{{ tag }}:{{ version }}" bootc install to-disk \
    --generic-image \
    --via-loopback \
    --root-ssh-authorized-keys=/target/authorized_keys \
    "/target/image/{{ tag }}.{{ version }}.raw"

gen-image version tag=_tag size="4G": (_gen-image _repo tag version size)

gen-image-local version tag=_tag size="4G":
  just _gen-image {{ _repo_local }} {{ tag }} {{ version }} {{ size }}
