#!/bin/bash

###############################################################################
# Script for jhead automation
# Author: Bastian Wagener
# Version: 0.1
###############################################################################

# Use only set variables
#set -u

# Constants
declare -ri OKAY=0
declare -ri ERROR=1

declare PATH_CORRECT_DATE
declare PATH_ADJUST_DATE
declare PATH_FOLDER
declare PATH_MERGE
declare PREFIX

#######################################
# Write log message
# Arguments:
#   Log message
#######################################
function log {
  local msg="$1"
  echo "$msg"
}

#######################################
# Check return value from previous call
#  and exit in case of error
# Arguments:
#   Error message
# o Log message 
#######################################
function checkReturn {
  if [[ "$?" -ne 0 ]]; then
    log "$1"
    exit $ERROR
  elif [[ -n "$2" ]]; then
    log "$2"
  fi
}

#######################################
# Displays usage information
#######################################
function disHelp {
  echo "Usage merge.sh -a <path> -m <path> -p <str> [-d <path>] [-h]" >&2
  echo " -a <path>     path to the picture which time will be adjusted" >&2
  echo " -m <path>     path to the picture with correct time" >&2
  echo " -p <str>      prefix used for new picture names <str>001.JPG" >&2
  echo " -d <path>     reads date and time the picture has been taken" >&2
  echo " -h            displays this message" >&2
}

#######################################
# Get options.
# Arguments:
#   Arguements to parse
#######################################
function getOptions {
  while getopts "a:m:p:d:h" opt; do
    case $opt in
	  a) PATH_ADJUST_DATE=$OPTARG ;;
	  m) PATH_CORRECT_DATE=$OPTARG ;;
	  p) PREFIX=$OPTARG ;;
	  d) getDate $OPTARG; exit 0;;
	  h) disHelp    ; exit 0;;
      \?) disHelp; exit 1 ;;
    esac
  done

  if [[ -z "$PATH_ADJUST_DATE" ]]; then
    echo "Adjust path not set!"
	disHelp
	exit $ERROR
  fi
  if [[ -z "$PATH_CORRECT_DATE" ]]; then
    echo "Correct path not set!"
	disHelp
	exit $ERROR
  fi
  if [[ -z "$PREFIX" ]]; then
    echo "Prefix not set!"
	disHelp
	exit $ERROR
  fi
  #PATH_CORRECT_DATE="./Pictures/Merge/IMG_1842.jpg"
  #PATH_ADJUST_DATE="./Pictures/AdjustDate/IMG_8739.jpg"
  PATH_FOLDER=$(dirname "$PATH_ADJUST_DATE")
  PATH_MERGE=$(dirname "$PATH_CORRECT_DATE")
  #PREFIX=TEST
}

#######################################
# Execute jhead. Adapt this according
#  to actual jhead executable.
#######################################
function jhead() {
  ./jhead.exe "$@"
}

#######################################
# Puts picture date in stdout
# Arguments:
#   Path to picture
#######################################
function getDate() {
  local m_path=$1
  # Added last grep for easy to use return code
  jhead $m_path 2>/dev/null | grep "Date/Time" | awk '{print $3 "/" $4}' | grep ":"
  checkReturn "Picture date could not be determined for $m_path!"
}

function main() {
  getOptions "$@"

  log "(1/5) Let's go!"
  echo "Correct date:"
  getDate $PATH_CORRECT_DATE
  echo "Date to adjust:"
  getDate $PATH_ADJUST_DATE
  jhead -da$(getDate $PATH_CORRECT_DATE)-$(getDate $PATH_ADJUST_DATE) $PATH_FOLDER/*
  checkReturn "Could not adjust date!" "(2/5) Dates adjusted."
  mv $PATH_FOLDER/* $PATH_MERGE/
  checkReturn "Could not move adjusted pictures!" "(3/5) Moved adjusted pictures."
  jhead -n%Y%m%d-%H%M%S $PATH_MERGE/*.jpg
  checkReturn "Could not rename pictures in merge directory!" "(4/5) Renamed pictures #1"
  jhead -n$PREFIX%03i $PATH_MERGE/*.jpg
  checkReturn "Could not rename pictures in merge directory!" "(5/5) Renamed pictures #2"
  exit $OKAY
}

main "$@"
