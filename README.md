# Mezeze

## Overview
Mezeze is a Bash script designed for AWS and Kubernetes environment management, including automated user creation, AWS CLI configuration, kubeconfig updates, kubectl aliases setup, and fzf installation. This repository also employs a GitHub Actions workflow for automated versioning and release management.

## Features

### Script Functionalities
- **User Creation and Setup:** Automates the creation of a new user and configures their environment for AWS and Kubernetes.
- **AWS CLI Configuration:** Sets up the AWS CLI for the newly created user.
- **Kubeconfig Management:** Automatically updates kubeconfig for specified EKS clusters.
- **Kubectl Aliases:** Adds useful kubectl aliases to the user's `.bashrc`.
- **FZF Installation:** Installs fzf, a command-line fuzzy finder.

### Automated Update Checks
- The script checks for its latest version at startup and prompts for an update if a newer version is available.

### GitHub Actions Workflow
- **Automated Version Increment:** Automatically updates the `SCRIPT_VERSION` on each merged pull request.
- **Release Management:** Creates a new GitHub release with the updated script version.

## Prerequisites
- Bash
- Access to AWS and Kubernetes environments
- Git (for cloning and contributing)

## Usage

1. **Clone the Repository:**
```
git clone https://github.com/PaulRoze/mezeze.git
```
2. **Run the Script:**
```
cd mezeze;
chmod +x mezeze.sh;
./mezeze.sh <username> <region> <environment>
```
Replace `<username>`, `<region>`, and `<environment>` with appropriate values.
You can provide only username, and the script will prompt for the rest of the values.

3. **Update Prompt:**
The script will prompt for updates if a new version is available.

## Script Help
To access the help menu for detailed usage instructions, run:
```
./mezeze.sh --help
```

## Contributing
Contributions to Mezeze are welcome. To contribute:

1. Fork the repository.
2. Create a feature branch.
3. Commit and push your changes.
4. Open a pull request against the `main` branch.

Contributions will automatically trigger the versioning and release workflow upon merge.

## Issues and Support
For issues, feature requests, or assistance, please open an issue in the repository.

## License
This project is released under the [MIT License](LICENSE).

## Acknowledgments
This project utilizes GitHub Actions for CI/CD, enhancing the software development process.
