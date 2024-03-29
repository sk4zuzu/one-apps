#!/usr/bin/env bash

# ---------------------------------------------------------------------------- #
# Copyright 2018-2019, OpenNebula Project, OpenNebula Systems                  #
#                                                                              #
# Licensed under the Apache License, Version 2.0 (the "License"); you may      #
# not use this file except in compliance with the License. You may obtain      #
# a copy of the License at                                                     #
#                                                                              #
# http://www.apache.org/licenses/LICENSE-2.0                                   #
#                                                                              #
# Unless required by applicable law or agreed to in writing, software          #
# distributed under the License is distributed on an "AS IS" BASIS,            #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.     #
# See the License for the specific language governing permissions and          #
# limitations under the License.                                               #
# ---------------------------------------------------------------------------- #

# USAGE:
#   service [-h|--help|help]
#       Print help and usage
#
#   service install [<version>]
#       Download files and install packages for the desired version of a service
#
#   service configure
#       Configure the service via contextualization or with defaults
#
#   service bootstrap
#       Use user's predefined values for the final setup and start the service

ONE_SERVICE_DIR=/etc/one-appliance
ONE_SERVICE_LOGDIR=/var/log/one-appliance
ONE_SERVICE_STATUS="${ONE_SERVICE_DIR}/status"
ONE_SERVICE_TEMPLATE="${ONE_SERVICE_DIR}/template"
ONE_SERVICE_METADATA="${ONE_SERVICE_DIR}/metadata"
ONE_SERVICE_REPORT="${ONE_SERVICE_DIR}/config"
ONE_SERVICE_FUNCTIONS="${ONE_SERVICE_DIR}/lib/functions.sh"
ONE_SERVICE_COMMON="${ONE_SERVICE_DIR}/lib/common.sh"
ONE_SERVICE_APPLIANCE="${ONE_SERVICE_DIR}/service.d/appliance.sh"
ONE_SERVICE_SETUP_DIR="/opt/one-appliance"
ONE_SERVICE_MOTD='/etc/motd'
ONE_SERVICE_PIDFILE="/var/run/one-appliance-service.pid"
ONE_SERVICE_CONTEXTFILE="${ONE_SERVICE_DIR}/context.json"
ONE_SERVICE_RECONFIGURE=false # the first time is always a full configuration
ONE_SERVICE_VERSION= # can be set by argument or to default
ONE_SERVICE_RECONFIGURABLE= # can be set by the appliance script

# security precautions
set -e
umask 0077

# -> TODO: read all from ONE_SERVICE_DIR

# source common functions
. "$ONE_SERVICE_COMMON"

# source this script's functions
. "$ONE_SERVICE_FUNCTIONS"

# source service appliance implementation (following functions):
#   service_help
#   service_install
#   service_configure
#   service_bootstrap
#   service_cleanup
. "$ONE_SERVICE_APPLIANCE"

# parse arguments and set _ACTION
_parse_arguments "$@"

# execute requested action or fail
case "$_ACTION" in
    nil|help)
        # check if the appliance defined a help function
        if type service_help >/dev/null 2>&1 ; then
            # use custom appliance help
            service_help
        else
            # use default
            default_service_help
        fi
        ;;
    badargs)
        exit 1
        ;;
    # all stages do basically this:
    #   1. check status file if _ACTION can be run at all
    #   2. set service status file
    #   3. set motd (message of the day)
    #   4. execute stage (install, configure or bootstrap)
    #   5. set service status file again
    #   6. set motd to normal or to signal failure
    install|configure|bootstrap)
        # check the status (am I running already)
        if _is_running ; then
            msg warning "Service script is running already - PID: $(_get_pid)"
            exit 0
        fi

        # secure lock or fail (only one running instance of this script is allowed)
        _lock_or_fail "$0" "$@"

        # set a trap for an exit (cleanup etc.)
        _trap_exit

        # write a pidfile
        _write_pid

        # analyze the current stage and either proceed or abort
        if ! _check_service_status $_ACTION "$ONE_SERVICE_RECONFIGURABLE" ; then
            exit 0
        fi

        # mark the start of a stage (install, configure or bootstrap)
        _set_service_status $_ACTION

        # here we make sure that log directory exists
        mkdir -p "$ONE_SERVICE_LOGDIR"
        chmod 0700 "$ONE_SERVICE_LOGDIR"

        # execute action
        _start_log "${ONE_SERVICE_LOGDIR}/${_ACTION}.log"
        service_${_ACTION} 2>&1
        _end_log

        # if we reached this point then the current stage was successfull
        _set_service_status success
        ;;
esac

exit 0
