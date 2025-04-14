function checkSetupMode{
  sbctl
  SETUP_MODE=$(sbctl | cut -d' ' -f1)
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
