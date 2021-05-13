#!/bin/bash

readonly my_name=saver

# - - - - - - - - - - - - - - - - - - - - - - - - - -

run_tests()
{
  local user="${1}"
  local type="${2}" # client|server
  local coverage_root="/tmp/${type}"
  local cid=$(docker ps --all --quiet --filter "name=test-${my_name}-${type}")

  echo
  echo "Running ${type} tests"

  set +e
  docker exec \
    --user "${user}" \
    --env COVERAGE_ROOT=${coverage_root} \
    "${cid}" \
      sh -c "/app/test/config/run.sh ${@:3}"
  local status=$?
  set -e

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # I would like to do this in docker-compose.yml
  #
  # saver:
  #  volume:
  #    ./tmp:/app/tmp:rw
  #
  # and write the coverage off /app/tmp thus avoiding
  # copying the coverage out of the container.
  # This works locally, but not on the CircleCI pipeline.
  # So I'm using a tmpfs: /tmp
  # You can't [docker cp] from a tmpfs, so tar-piping coverage out.

  local cov_dir="${ROOT_DIR}/coverage"
  echo "Copying statement coverage files to ${cov_dir}/${type}"
  mkdir -p "${cov_dir}"

  docker exec "${cid}" \
    tar Ccf \
      "$(dirname "${coverage_root}")" \
      - "$(basename "${coverage_root}")" \
        | tar Cxf "${cov_dir}/" -

  cat "${cov_dir}/${type}/done.txt"

  return ${status}
}

# - - - - - - - - - - - - - - - - - - - - - - - - - -
declare server_status=0
declare client_status=0

# - - - - - - - - - - - - - - - - - - - - - - - - - -
run_server_tests()
{
  run_tests saver server "${@:-}"
  server_status=$?
}

# - - - - - - - - - - - - - - - - - - - - - - - - - -
run_client_tests()
{
  run_tests nobody client "${@:-}"
  client_status=$?
}

# - - - - - - - - - - - - - - - - - - - - - - - - - -
run_tests_in_containers()
{
  if [ "${1:-}" == server ]; then
    shift
    run_server_tests "$@"
  elif [ "${1:-}" == client ]; then
    shift
    run_client_tests "$@"
  else
    run_server_tests "$@"
    run_client_tests "$@"
  fi

  if [ "${server_status}" == "0" ] && [ "${client_status}" == "0" ]; then
    echo '------------------------------------------------------'
    echo 'All passed'
    echo
    return 0
  else
    echo
    echo "test-${my_name}-server: status = ${server_status}"
    echo "test-${my_name}-client: status = ${client_status}"
    echo
    return 1
  fi
}

