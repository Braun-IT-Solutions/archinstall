# BITS Arch Install Script

This project provides a set of scripts to automate the installation and configuration of Arch Linux for development PCs. The entry point for the installation process is the `install.sh` script.

## Features

- Automated disk partitioning and formatting.
- Secure Boot setup with key generation and signing.
- LUKS encryption with recovery key generation.
- User creation and environment setup.
- Installation of essential packages and configuration of system services.

## Prerequisites

- A target machine with UEFI firmware.
- A USB drive with an Arch Linux live environment.
- Internet connection during installation.

## Usage

1. Boot into the Arch Linux live environment.
2. Clone this repository or copy the scripts to the live environment.
3. Run the `install.sh` script:

   ```bash
   ./install.sh
   ```

4. Follow the on-screen prompts to complete the installation.

## Script Overview

- **`install.sh`**: Entry point for the installation process. Handles user input and orchestrates the execution of other scripts.
- **`partition.sh`**: Handles disk partitioning, formatting, and mounting.
- **`configuration.sh`**: Installs base packages, configures the system, and sets up the user environment.
- **`secure-boot.sh`**: Configures Secure Boot, generates keys, and signs binaries.
- **`util.sh`**: Utility functions for colored output and other helper tasks.

## Notes

- The scripts are tailored for development PCs and may require adjustments for other use cases.
- Ensure that Secure Boot is set to setup mode in the BIOS before running the scripts.
- Store the generated recovery key securely.

## License

This project is licensed under the MIT License.
