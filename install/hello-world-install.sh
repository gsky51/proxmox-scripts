#!/usr/bin/env bash
# Copyright (c) 2026 James J Greensky
# Author: gsky51
# License: MIT

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Hello-World"
mkdir -p /opt/hello-world
{
  echo "Hello from $(hostname) at $(date)"
  echo "MARKER-$(date +%s)"
} > /opt/hello-world/hello.txt
msg_ok "Installed Hello-World"

motd_ssh
customize
cleanup_lxc
