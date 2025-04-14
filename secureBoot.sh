function checkSetupMode{
  SETUP_MODE=$(sbctl status)
  echo $SETUP_MODE
}

function createKeysAndSign{
  sbctl create-keys
  sbctl enroll-keys -m

  sbctl sign -s -o /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed
  sbctl sign -s /efi/EFI/BOOT/BOOTX64.efi
  sbctl sign -s /efi/EFI/Linux/arch-linux.efi
  sbctl sign -s /efi/EFI/Linux/arch-linux-fallback.efi

  mkinitcpio -P 
}

checkSetupMode
createKeysAndSign

#./tpm2.sh