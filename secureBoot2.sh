function rollOutTPM2(){
  chmod go-r luks-temp.key
  echo "TPM2 ausrollen..." > /dev/tty
  $(systemd-cryptenroll --tpm2-device=auto --wipe-slot=tpm2 --tpm2-pcrs=0+7 --unlock-key-file=luks-temp.key /dev/gpt-auto-root-luks)

  echo "Delete Initial Password..." > /dev/tty
  #systemd-cryptenroll /dev/gpt-auto-root-luks --wipe-slot=password
}
set -eo pipefail


rollOutTPM2