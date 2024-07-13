#!/usr/bin/env bash

## ORIGINALLY FROM: https://dev.to/pencillr/test-ansible-playbooks-using-docker-ci0
## MODIFIED TO MEET MY NEEDS

# -e: Exit immediately if a command exits with a non-zero status.
# -u: Treat unset variables as an error when substituting.
# -o pipeline: return the exit status of the last command in the pipe that returned a non-zero exit code.
set -euo pipefail

# Generate a random 5-char identifier for the container name
identifier="$(< /dev/urandom tr -dc 'a-z0-9' | fold -w 5 | head -n 1)" ||:
NAME="debian-env-test-${identifier}"

# Get the dir of the script
base_dir="$(dirname "$(readlink -f "$0")")"

# Function to clean up resources on exit or error
function cleanup() {
    container_id=$(docker inspect --format="{{.Id}}" "${NAME}" ||:)
    if [[ -n "${container_id}" ]]; then
        echo "Cleaning up container ${NAME}"
        docker rm --force "${container_id}"
    fi
    if [[ -n "${TEMP_DIR:-}" && -d "${TEMP_DIR:-}" ]]; then
        echo "Cleaning up tempdir ${TEMP_DIR}"
        rm -rf "${TEMP_DIR}"
    fi
}

# Create temporary directory
function setup_tempdir() {
    TEMP_DIR=$(mktemp --directory "/tmp/${NAME}".XXXXXXXX)
    export TEMP_DIR
}

# Create temporary SSH key
function create_temporary_ssh_id() {
    ssh-keygen -b 2048 -t rsa -C "${USER}@email.com" -f "${TEMP_DIR}/id_rsa" -N ""
    chmod 600 "${TEMP_DIR}/id_rsa"
    chmod 644 "${TEMP_DIR}/id_rsa.pub"
}

# Build and start the container
function start_container() {
    # Build the docker image
    docker build --tag "debian-env-test" \
        --build-arg USER \
        --file "${base_dir}/Dockerfile" \
        "${TEMP_DIR}"

    # Run the container
    docker run -d -p 127.0.0.1:2222:22 --name "${NAME}" "debian-env-test"

    # Get the IP address of the container
    CONTAINER_ADDR=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${NAME}")
    export CONTAINER_ADDR
}

# Setup the temporary ansible inventory file
function setup_test_inventory() {
    TEMP_INVENTORY_FILE="${TEMP_DIR}/hosts"

    cat > "${TEMP_INVENTORY_FILE}" << EOL
[target_group]
127.0.0.1:2222
[target_group:vars]
ansible_ssh_private_key_file=${TEMP_DIR}/id_rsa
EOL
    export TEMP_INVENTORY_FILE
}

# Run the Ansible playbook
function run_ansible_playbook() {
    ANSIBLE_CONFIG="${base_dir}/ansible.cfg"
    ansible-playbook -i "${TEMP_INVENTORY_FILE}" -vvv "${base_dir}/deploy.yml"
}

# Function that asks user if they want to enter the container before exiting
function enter_container() {
  read -p "Do you want to enter the container? [y/n]" is_entering
  if [[ "${is_entering}" == "y" ]]; then
    docker exec -it "${NAME}" /bin/bash
  fi

  read -p "Do you want to perform a cleanup on the test resources? [y/n]" do_cleanup
  if [[ "${do_cleanup}" == "y"  ]]; then
    cleanup
  fi
}

# Main execution flow
setup_tempdir
trap cleanup EXIT
trap cleanup ERR
create_temporary_ssh_id
start_container
setup_test_inventory
run_ansible_playbook
enter_container
