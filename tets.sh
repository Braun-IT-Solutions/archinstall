#!/usr/bin/bash

FLAG=$(cat "tmp.txt")
  if [ "$FLAG" -eq 1 ] 2>/dev/null; then
  echo "2" > tmp.txt
  echo "1 done"
  else
    echo "1" > tmp.txt
   echo "2 done"
  fi