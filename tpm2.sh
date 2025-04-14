#!/usr/bin/bash


function recoveryKey {

  echo "Recovery Key generieren..." > /dev/tty
  systemd-cryptenroll /dev/gpt-auto-root-luks --recovery-key > recovery_key.txt

  echo "TPM2 ausrollen..." > /dev/tty
  systemd-cryptenroll --tpm2-device=auto --wipe-slot=tpm2 --tpm2-pcrs=0+7 /dev/gpt-auto-root-luks

  echo "Delete Initial Password..." > /dev/tty
  systemd-cryptenroll /dev/gpt-auto-root-luks --wipe-slot=password

}
set -eo pipefail

recoveryKey