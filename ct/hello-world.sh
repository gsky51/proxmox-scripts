#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/gsky51/proxmox-scripts/main/misc/build.func)
# Copyright (c) 2026 James J Greensky
# Author: gsky51
# License: MIT
# Source: https://github.com/gsky51/proxmox-scripts

APP="Hello-World"
var_tags="${var_tags:-demo}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
var_disk="${var_disk:-2}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /opt/hello-world/hello.txt ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi
  msg_info "Updating ${APP}"
  echo "Updated at $(date)" >> /opt/hello-world/hello.txt
  msg_ok "Updated ${APP}"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Container is ready. Exec in with: pct enter \$CTID${CL}"
