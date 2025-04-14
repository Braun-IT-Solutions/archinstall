#!/usr/bin/bash


function recoveryKey {
  systemd-cryptenroll /dev/gpt-auto-root-luks --recovery-key > recovery_key.txt
  systemd-cryptenroll --tpm2-device=auto --wipe-slot=tpm2 --tpm2-pcrs=0+7 /dev/gtp-auto-root-luks
  systemd-cryptenroll /dev/gpt-auto-root-luks --wipe-slot=password

}