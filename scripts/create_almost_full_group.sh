#!/bin/bash -Eeu

# Ensure server-container is up before running this script.
# $ ./up.sh

export ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SCRIPTS_DIR="${ROOT_DIR}/scripts"
source "${SCRIPTS_DIR}/config.sh"

readonly version="${1:-}"

docker exec "$(server_container)" bash -c "rm -rf /cyber-dojo/*"

gid=$(docker exec \
  --user "$(server_user)" \
  "$(server_container)" \
  bash -c "ruby /app/test/data/create_almost_full_group.rb ${version}")

src_dir=/cyber-dojo
dst_tgz_filename="${ROOT_DIR}/app/test/data/almost_full_group.v${version}.${gid}.tgz"

#extract /cyber-dojo from server_cid into tgz file
docker exec $(server_container) \
  tar -zcf - -C $(dirname ${src_dir}) $(basename ${src_dir}) \
    > "${dst_tgz_filename}"

echo "Filename == ${dst_tgz_filename}"
