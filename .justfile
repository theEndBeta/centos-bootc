name := "c10"
tag := "centos10"

[private]
default:
  just --list

build tag=tag:
  podman build . -f Containerfile -t {{ tag }}

run name=name tag=tag:
  podman run --detach --replace --name {{ name }} {{ tag }}

exec name=name:
  podman exec -it {{ name }} /bin/bash

run-it name=name tag=tag:
  podman run --rm -it {{ tag }} /bin/bash
