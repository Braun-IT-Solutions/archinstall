#!/bin/bash
GREEN="\033[32m"
RED="\033[31m"
CYAN="\033[36m"
YELLOW="\033[33m"

END="\033[0m"


#Returns String with red or green prefix, can be echo'ed with -e flag, default to white
function printColor(){
  if [[ -n $1 ]] && [[ -n $2 ]]; then
    if [[ $2 == "GREEN" ]]; then
      RETURN="${GREEN}${1}${END}"
      echo -e "${RETURN}" > /dev/tty
    elif [[ $2 == "RED" ]]; then
      RETURN="${RED}${1}${END}"
      echo -e "${RETURN}" > /dev/tty
    elif [[ $2 == "CYAN" ]]; then
      RETURN="${CYAN}${1}${END}"
      echo -e "${RETURN}" > /dev/tty
    elif [[ $2 == "YELLOW" ]]; then
      RETURN="${YELLOW}${1}${END}"
      echo -e "${RETURN}" > /dev/tty
    else
      echo -e "${1}" > /dev/tty
    fi
  fi
}