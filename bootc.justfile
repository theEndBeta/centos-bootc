# _name := "f42"
# _repo := "quay.io/theendbeta"
# _repo_local := "localhost:5000"
# _tag := "fedora42-bootc"
# _version := `date +'%Y%m%d%H%M'`

[private]
default:
  just --list

[private]
[no-cd]
_build repo tag version:
  podman build . --pull=newer -f Containerfile \
    -t "{{ repo }}/{{ tag }}:{{ version }}" \
    -t "{{ repo }}/{{ tag }}:latest"

[private]
_push repo tag version:
  podman push "{{repo}}/{{ tag }}:{{ version }}"

[private]
[group("container")]
_run name tag repo:
  podman run --detach --replace --name {{ name }} "{{ repo }}/{{ tag }}"

[private]
[group("container")]
_run-it name tag repo:
 podman run --rm -it --name {{ name }} "{{ repo }}/{{ tag }}" /bin/bash

[group("vm")]
[no-cd]
vm-launch variant version name:
  sudo virt-install \
    --name {{ name }}-{{ version }} \
    --cpu host-model \
    --vcpus 4 \
    --memory 4096 \
    --import \
    --disk ./image/{{ name }}.{{ version }}.raw,format=raw \
    --autoconsole text \
    --os-variant={{ variant }}

[private]
[group("vm")]
vm-start version name:
  sudo virsh start --console {{ name }}-{{ version }}

[private]
[group("vm")]
vm-stop version name:
  sudo virsh shutdown {{ name }}-{{ version }}

[private]
[group("vm")]
vm-delete version name:
  sudo virsh undefine {{ name }}-{{ version }} --remove-all-storage
