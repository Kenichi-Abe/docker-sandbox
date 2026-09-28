FROM registry.access.redhat.com/ubi9/ubi-minimal:9.2

RUN microdnf -y install --setopt=install_weak_deps=0 \
      python3.11 python3.11-pip \
      openssh-clients \
    && microdnf clean all \
    && pip3.11 install --no-cache-dir \
      'ansible-core==2.14.2' 'pywinrm'

# よく使う collection もここで固定する（オフライン対策）
RUN ANSIBLE_GALAXY_SERVER_TIMEOUT=300 ansible-galaxy collection install \
      community.general:9.5.13 ansible.posix:1.5.4 ansible.windows:2.4.0 community.windows:2.2.0 containers.podman:1.20.2 \
      -p /usr/share/ansible/collections

WORKDIR /workspace