#!/bin/bash
#
# The Condo installers helps to install Condo.
set -u


readonly CONDO_HOME=/usr/local/Condo
readonly CONDO_CONFIG_DIR=$HOME/.condo

readonly CONDO_SCRIPT_URL="https://raw.githubusercontent.com/jsdjayanga/condo/main/condo/condo.sh"
readonly CONDO_CONFIG_URL="https://raw.githubusercontent.com/jsdjayanga/condo/main/config/condo.json"

readonly CONDO_UNINSTALL_SCRIPT_URL="https://raw.githubusercontent.com/jsdjayanga/condo/main/scripts/uninstall.sh"
readonly JSON_PARSER_SCRIPT_URL="https://raw.githubusercontent.com/jsdjayanga/condo/main/scripts/json.sh"

CONDO_SCRIPT=$CONDO_HOME/condo.sh
CONDO_UNINSTALL_SCRIPT=$CONDO_HOME/uninstall.sh

CONDO_CONFIG=$CONDO_CONFIG_DIR/condo.json
CONDO_EXECUTABLE_SYMLINK=/usr/local/bin/condo

###############################################################################
# Creates Condo home directory if it does not exist
###############################################################################
create_condo_home () {
  if ! [[ -d "$CONDO_HOME" ]]; then
    sudo "/bin/mkdir" "-p" "$CONDO_HOME"
  fi
  sudo chown "$USER:admin" "$CONDO_HOME"
}

###############################################################################
# Creates Condo config directory if it does not exist
###############################################################################
create_condo_config_dir () {
  if ! [[ -d "$CONDO_CONFIG_DIR" ]]; then
    sudo "/bin/mkdir" "-p" "$CONDO_CONFIG_DIR"
  fi
  sudo chown "$USER:admin" "$CONDO_CONFIG_DIR"
}

###############################################################################
# Installs Condo script and set proper execution permissions
###############################################################################
install_condo_script () {
  local condo_script=$CONDO_HOME/condo.sh
  local condo_script_source=$(curl -fsSL $CONDO_SCRIPT_URL)
  sudo echo "$condo_script_source" > $condo_script
  sudo chmod 777 $condo_script
  sudo ln -sf $condo_script /usr/local/bin/condo
}

###############################################################################
# Installs Condo uninstallation script
###############################################################################
install_uninstallation_script () {
  local condo_uninstall_script_source=$(curl -fsSL $CONDO_UNINSTALL_SCRIPT_URL)
  sudo echo "$condo_uninstall_script_source" > $CONDO_HOME/uninstall.sh
}

###############################################################################
# Copies sample condo config file if not available to the CONDO_HOME
###############################################################################
copy_condo_config () {
  local condo_config=$CONDO_CONFIG_DIR/condo.json
  if ! [[ -f "$condo_config" ]]; then
    condo_config_source=$(curl -fsSL $CONDO_CONFIG_URL)
    sudo echo "$condo_config_source" > $condo_config
  fi
}

###############################################################################
# Copies JSON parser script to CONDO_HOME
###############################################################################
copy_json_parser_script () {
  local json_parser_script_source=$(curl -fsSL $JSON_PARSER_SCRIPT_URL)
  sudo echo "$json_parser_script_source" > $CONDO_HOME/json.sh
}

create_condo_home
create_condo_config_dir
install_condo_script
install_uninstallation_script
copy_condo_config
copy_json_parser_script
