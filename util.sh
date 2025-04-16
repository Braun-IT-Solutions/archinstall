#!/bin/bash
GREEN="\033[32m"
RED="\033[31m"
END="\033[0m"

#Returns String with red or green prefix, can be echo'ed with -e flag, default to white
function printColor(){
  if [[ -n $1 ]] && [[ -n $2 ]]; then
    if [[ $2 == "GREEN" ]]; then
      RETURN="${GREEN}${1}${END}"
      echo "${RETURN}"
    elif [[ $2 == "RED" ]]; then
      RETURN="${RED}${1}${END}"
      echo "${RETURN}"
    else
      echo "${1}"
    fi
  fi
}