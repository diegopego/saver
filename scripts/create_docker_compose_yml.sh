#!/bin/bash -Eeu

create_docker_compose_yml()
{
  echo_docker_compose_yml > ${ROOT_DIR}/docker-compose.yml
}

echo_docker_compose_yml()
{
# Use un-expanded ${COMMIT_TAG} to avoid needless git diff churn.
cat <<-EOF
# This file was generated by ./scripts/create_docker_compose_yml.sh

version: '3.7'

volumes:
  one_k:
    external: true

services:

  $(client_name):
    build:
      args: [ COMMIT_SHA ]
      context: $(client_context)
    image: $(client_image):\${COMMIT_TAG}
    container_name: $(client_container)
    user: $(client_user)
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
    build:
      args: [ COMMIT_SHA ]
      context: $(server_context)
    image: $(server_image):\${COMMIT_TAG}
    user: $(server_user)
    container_name: $(server_container)
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
    depends_on:
      - custom-start-points

  custom-start-points:
    image: ${CYBER_DOJO_CUSTOM_START_POINTS_IMAGE}:${CYBER_DOJO_CUSTOM_START_POINTS_TAG}
    container_name: test_saver_custom_start_points
    user: nobody
    env_file: [ .env ]
    read_only: true
    restart: "no"
    tmpfs: /tmp
	
EOF
}
