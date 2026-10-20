#!/bin/bash

set -eu

source metadata
source libs/console.sh

CONTAINER_NAME="ansible-client"
TARBALL="portable-ansible-${VERSION}-py3.tar.gz"

function help() {

    echo "Usage: client <action>"
    echo 
    echo "  action:"
    echo "      start: start client"
    echo "      stop: stop client"
    echo "      console: open console to client"
    echo "      local_tests: run local tests"
    echo "      remove_tests: run remote tests"
    echo
}

function start() {

    ./libs/container.sh start ${CONTAINER_NAME}

    info "Preparing Ansible Client" && \
        ./libs/container.sh exec ${CONTAINER_NAME} \
            dnf update -q -y && \
        ./libs/container.sh exec ${CONTAINER_NAME} \
            dnf install -y openssh-clients ncurses bzip2 && \
        ./libs/container.sh exec ${CONTAINER_NAME} rm -rf /workspace/opt && \
        ./libs/container.sh exec ${CONTAINER_NAME} mkdir -p /workspace/opt && \
        ./libs/container.sh exec ${CONTAINER_NAME} \
            tar -xf /workspace/builds/${TARBALL} -C /workspace/opt/ && \
        ./libs/container.sh exec ${CONTAINER_NAME} \
            ln -s /workspace/opt/ansible /workspace/opt/ansible-playbook
}

function stop() {

    ./libs/container.sh stop ${CONTAINER_NAME}
}

function restart() {

    stop
    start
}

function console() {

    ./libs/container.sh console ${CONTAINER_NAME}
}

function local_tests() {

    ./libs/container.sh exec ${CONTAINER_NAME} \
        python3.12 /workspace/opt/ansible-playbook -v \
            -i /workspace/test/hosts.yaml \
            /workspace/test/playbooks/local.yaml
}

function remote_tests() {

    ./libs/container.sh exec ${CONTAINER_NAME} \
        python3.12 /workspace/opt/ansible-playbook -v -i /workspace/test/hosts.yaml \
            /workspace/test/playbooks/remote-via-ssh-key.yaml

    ./libs/container.sh exec ${CONTAINER_NAME} \
        python3.12 /workspace/opt/ansible-playbook -v -i /workspace/test/hosts.yaml \
            /workspace/test/playbooks/remote-via-username-and-password.yaml
}


$@
