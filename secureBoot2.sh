function rollOutTPM2(){
  chmod go-r luks-temp.key
  echo "TPM2 ausrollen..."
  $(systemd-cryptenroll --tpm2-device=auto --wipe-slot=tpm2 --tpm2-pcrs=0+7 --unlock-key-file=luks-temp.key /dev/gpt-auto-root-luks)

  echo "Delete Initial Password..."
  #systemd-cryptenroll /dev/gpt-auto-root-luks --wipe-slot=password

  rm -rf /home/pascal.brus/.bachrc
  cp /home/pascal.brus/.bashrcBACKUP /home/pascal.brus/.bashrc


  #systenctl reboot
}
set -eo pipefail

rollOutTPM2
