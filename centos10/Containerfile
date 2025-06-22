FROM quay.io/centos-bootc/centos-bootc:stream10

RUN echo '[etc]' >> /usr/lib/ostree/prepare-root.conf \
    && echo 'transient = true' >> /usr/lib/ostree/prepare-root.conf

COPY ./system/wheel-passwordless-sudo /etc/sudoers.d/wheel-passwordless-sudo

# Filesystem
# RUN mkdir /var/roothome
# RUN useradd $USERNAME \
#   -u 1000 \
#   -K SUB_GID_MIN=1000001 \
#   -K SUB_UID_MIN=1000001 \
#   -G wheel \
#   -p '$y$j9T$rgIIgXU.iiGCNeGeo27Va1$.UbQgNafnJ0.OX7MIYunDIKU2T5dySSoLuC8I9kxke6'

COPY --chmod=0644 ./sysusers.conf /usr/lib/sysusers.d/podman.conf
# COPY --chmod=0644 ./vesu2.json /usr/etc/userdb/vesu2.user
# COPY --chmod=0644 ./vesu2.priv.json /usr/etc/userdb/vesu2.user-privileged

# Packages
COPY --chmod=0644 ./packages.json /usr/local/share/bootc/packages.json
RUN jq -r .packages[] /usr/share/rpm-ostree/treefile.json > /usr/local/share/bootc/packages-centos-bootc \
    && jq -r '.add | flatten | join(" ")' /usr/local/share/bootc/packages.json

COPY --chmod=0644 ./wezterm-nightly.repo "/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:wezfurlong:wezterm-nightly.repo"
RUN --mount=type=cache,id=libdnf,target="/var/lib/dnf" \
    --mount=type=cache,id=cachednf,target="/var/cache/dnf" \
  dnf config-manager --set-enabled crb \
  && dnf install -y centos-release-hyperscale \
  && dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm \
  && dnf config-manager -y --add-repo="https://pkgs.tailscale.com/stable/fedora/tailscale.repo"

RUN --mount=type=cache,id=libdnf,target="/var/lib/dnf" \
    --mount=type=cache,id=cachednf,target="/var/cache/dnf" \
  dnf -y --allowerasing --nodocs install $(jq -r '.add | flatten | join(" ")' "/usr/local/share/bootc/packages.json") \
  && dnf -y remove $(jq -r '.remove | flatten | join(" ")' "/usr/local/share/bootc/packages.json") \
  && rm /usr/bin/wezterm-gui \
  && dnf -y autoremove \
  && dnf clean all

COPY ./wezterm.terminfo /tmp/wezterm.terminfo
RUN tic -x -o /usr/share/terminfo /tmp/wezterm.terminfo

# config
COPY --chmod=0755 ./scripts/* /usr/local/bin/
COPY --chmod=0644 ./system/etc_skel_bashrcd /etc/skel/.bashrc.d/bootc
COPY --chmod=0644 ./system/kargs_00-console.toml /usr/lib/bootc/kargs.d/00-console.toml
# COPY --chmod=0640 --chown="${USERNAME}:${USERNAME}" ./home/* "/home/${USERNAME}/"

# RUN mkdir -p /home/${USERNAME}/.ssh
# COPY --chown="${USERNAME}:${USERNAME}" --chmod=0640 ./authorized_keys /home/${USERNAME}/.ssh/authorized_keys
# COPY --chmod=0640 ./authorized_keys /var/roothome/.ssh/authorized_keys

# SYSTEMD
COPY --chmod=0644 ./systemd/firstboot-setup.service /usr/lib/systemd/system/firstboot-setup.service


# RUN mkdir -p /usr/lib/userdb
COPY --chmod=0644 ./vesu2.json /usr/lib/credstore/home.create.vesu
# COPY --chmod=0644 ./vesu2.json /usr/lib/userdb/vesu2.user
# COPY --chmod=0600 ./vesu2.priv.json /usr/lib/userdb/vesu2.user-privileged
# RUN ln -s /usr/lib/userdb/vesu2.user /usr/lib/userdb/1005.user \
#     && ln -s /usr/lib/userdb/vesu2.user-privileged /usr/lib/userdb/1005.user-privileged
# RUN set -x; kver='$(cd /usr/lib/modules && echo *)'; dracut -vf /usr/lib/modules/$kver/initramfs.img $kver
RUN rm /var/{log,cache,lib}/* -rf

RUN systemctl enable bootc-fetch-apply-updates.timer tailscaled.service systemd-homed.service systemd-homed-firstboot.service

RUN bootc container lint

# vim: set ft=dockerfile:
