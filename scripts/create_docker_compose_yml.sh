#!/bin/bash -Eeu

create_docker_compose_yml()
{
  echo_docker_compose_yml > ${ROOT_DIR}/docker-compose.yml
}

echo_docker_compose_yml()
{
# Use un-expanded ${COMMIT_TAG} to avoid needless git diff churn.
cat <<-EOF
# This file was auto-generated by ./scripts/create_docker_compose_yml.sh
# It is used by ./scripts/augmented_docker_compose.sh
# which saves a copy of the fully-augmented docker-compose.yml
# generated for each build/up/wait/test command
# in \${ROOT_DIR}/tmp/

version: '3.7'

volumes:
  one_k:
    external: true

services:

  $(client_name):
    image: $(client_image):\${COMMIT_TAG}
    user: $(client_user)
    build:
      args: [ COMMIT_SHA ]
      context: $(client_context)
    container_name: $(client_container)
    env_file: [ .env ]
    read_only: true
    restart: 'no'
    tmpfs: /tmp
    volumes:
      - $(client_context)/source:/app/source:ro
      - $(client_context)/test:/app/test:ro
    depends_on:
      - custom-start-points
      - $(server_name)

  $(server_name):
    image: $(server_image):\${COMMIT_TAG}
    user: $(server_user)
    build:
      args: [ COMMIT_SHA ]
      context: $(server_context)
    container_name: $(server_container)
    depends_on:
      - custom-start-points
    env_file: [ .env ]
    read_only: true
    restart: "no"
    volumes:
      - $(server_context)/app/source:/app/source:ro
      - $(server_context)/app/test:/app/test:ro
      - one_k:/one_k:rw
    tmpfs:
      - /cyber-dojo:uid=19663,gid=65533
      - /tmp:uid=19663,gid=65533

EOF
}
