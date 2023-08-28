# Mezeze Automation Script

## Overview

The `mezeze.sh` script is designed to automate several tasks related to setting up a new user environment. Specifically, it handles:

- Checking for and pulling the latest version of the script.
- Creating a new user.
- Setting up the AWS CLI.
- Updating the kubeconfig for the user.
- Adding useful `kubectl` aliases.
- Installing and configuring `fzf`, a command-line fuzzy finder.

## Prerequisites

- The script should be run as the root user.
- AWS CLI should be installed and configured on the machine.
- `git` should be installed on the machine.

## Usage

To run the script, use the following command:

```bash
./mezeze.sh <username> <region> <environment>
```

### Arguments:

- `<username>`: The name of the user to create.
- `<region>`: The AWS region where the EKS clusters are located. If not provided, the script will attempt to determine the region automatically.
- `<environment>`: The environment name used to construct EKS cluster names for kubeconfig. If not provided, the script will attempt to determine the environment automatically.

You can also view the usage instructions by running:

```bash
./mezeze.sh --help
```

## Features

### Update Check

The script checks for updates from the remote repository. If a newer version is available, it will prompt the user to update. If the user agrees, the script will pull the latest changes and re-run itself.

### User Creation

If the provided username does not exist on the system, the script will create a new user with the given username.

### AWS CLI and Kubeconfig Setup

The script sets up the AWS CLI and updates the kubeconfig for the created user. It also adds several useful `kubectl` aliases to the user's `.bashrc` file.

### `fzf` Installation

The script checks if `fzf` is installed for the user. If not, it will offer to install it. If `fzf` is already installed, it will offer to remove it.

## Feedback and Contributions

If you encounter any issues or have suggestions for improvements, please open an issue on the [GitHub repository](https://github.com/PaulRoze/mezeze). Contributions are welcome!
