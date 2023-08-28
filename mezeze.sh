#!/bin/bash

# ------------------------------
# Helper Functions
# ------------------------------

usage() {
    echo "Usage: $0 <username> <region> <environment>"
    echo ""
    echo "Purpose: Automate user creation, AWS CLI setup, kubeconfig update, kubectl alias addition, and fzf installation."
    echo ""
    echo "Arguments:"
    echo "  <username>: Name of the user to create."
    echo "  <region>: AWS region with EKS clusters."
    echo "  <environment>: Environment name for EKS cluster kubeconfig."
    echo ""
    echo "Note: The script sets up AWS CLI, updates kubeconfig, adds kubectl aliases, and installs fzf for the user."
    exit 1
}

check_for_updates() {
    if [ "$CHECK_FOR_UPDATES" = false ]; then
        return
    fi

    cd "$REPO_DIR"
    git fetch -q
    git reset --hard origin/main -q

    if git status -uno | grep -q 'Your branch is behind'; then
        case $yn_update in
            [Yy]* )
                git pull -q
                chmod +x "$SCRIPT_PATH"
                echo "Script updated. Please wait..."
                CHECK_FOR_UPDATES=false exec env CHECK_FOR_UPDATES=false "$SCRIPT_PATH" $ORIGINAL_ARGS
                exit 0
                ;;
            * ) ;;
        esac
    fi

    chmod +x "$SCRIPT_PATH"
}

# ------------------------------
# Initial Validations
# ------------------------------

# Ensure root execution
if [[ $EUID -ne 0 ]]; then
   echo "Error: Run this script as root."
   exit 1
fi

# Validate git installation
if ! command -v git &>/dev/null; then
    echo "Error: Install git and retry."
    exit 1
fi

# Validate AWS CLI installation
if ! command -v aws &>/dev/null; then
    echo "Error: Install AWS CLI and retry."
    exit 1
fi

# Validate AWS CLI configuration
if ! aws sts get-caller-identity &>/dev/null; then
    echo "Error: Configure AWS CLI using 'aws configure'."
    exit 1
fi

# ------------------------------
# Script Configuration
# ------------------------------

REPO_DIR="/opt/kaltura/mezeze"
SCRIPT_PATH="$REPO_DIR/mezeze.sh"
REMOTE_REPO="https://github.com/PaulRoze/mezeze.git"
ORIGINAL_ARGS="$@"
CHECK_FOR_UPDATES=${CHECK_FOR_UPDATES:-true}

# Check for script updates
check_for_updates

# Validate user input
if [[ $1 == "--help" || $1 == "-h" ]]; then
    usage
fi

if [[ $# -lt 1 ]]; then
    echo "Error: Provide more arguments."
    usage
fi

# Validate username
if [[ ! "$1" =~ ^[a-zA-Z0-9_\-]+$ ]]; then
    echo "Error: Invalid username. Only alphanumeric characters, underscores, and dashes are allowed."
    exit 1
fi

# Set region and environment
username=$1
region=${2:-$(ec2-metadata -z| awk '{print $NF}' | sed 's/.$//g')}
environment=${3:-$(ec2-metadata -u | awk -F: '/keyname:/ {print $NF}' | awk -F- '{print $1}')}

# Confirm region and environment
read -r -p "Running with region [default: ${region}]: " -i ${region} input_region
region=${input_region:-$region}
read -r -p "Running with env [default: ${environment}]: " -i ${environment} input_env
environment=${input_env:-$environment}

# Display configurations
echo "Configurations:"
echo "Username: [${username}]"
echo "Environment: [${environment}]"
echo "Region: [${region}]"

# Check if user exists
if id "$username" &>/dev/null; then
    echo "User '$username' already exists."
    read -p "Do you want to continue and update the kubeconfig for ${username}? [y/N] " yn
    case $yn in
        [Yy]* ) ;;
        * ) exit;;
    esac
else
    useradd -m -s /bin/bash "$username" || { echo "Failed to create user '$username'"; exit 1; }
    echo "User '$username' created successfully."
fi

# Check region
if [ -z "$region" ]; then
    echo "Error: AWS region not set. Please set the region by running 'aws configure' or provide it as an argument."
    exit 1
fi

# Update kubeconfig
CLUSTER_LIST=$(aws eks list-clusters --query 'clusters[]' --output text --region ${region})
for cluster in $CLUSTER_LIST ; do
    if [[ $cluster == *"$environment"* ]]; then
        sudo -u $username sh -c "PATH=/usr/local/bin:$PATH aws eks update-kubeconfig --name ${cluster} --region ${region}" || echo "Failed to update kubeconfig for ${cluster}"
    fi
done
echo "Kubeconfig updated successfully for user '$username'."

# Update kubectl aliases
ALIAS_FILE="/home/$username/.k8s_aliases"
if [ -f "$ALIAS_FILE" ]; then
    echo "Kubernetes aliases file .k8s_aliases already exists for user $username."
    read -p "Do you want to overwrite the existing Kubernetes aliases? [y/N] " yn
    case $yn in
        [Yy]* )
            echo '
            # kubernetes
            alias k="kubectl"
            # ... [rest of the aliases]
            alias kgpn="kgp --output=jsonpath={.items..metadata.name}"' > $ALIAS_FILE
            ;;
        * ) echo "Not overwriting the existing Kubernetes aliases.";;
    esac
else
    echo '
    # kubernetes
    alias k="kubectl"
    # ... [rest of the aliases]
    alias kgpn="kgp --output=jsonpath={.items..metadata.name}"' > $ALIAS_FILE
fi

# Source k8s aliases in .bashrc
if ! sudo -u $username grep -q "source /home/$username/.k8s_aliases" /home/$username/.bashrc; then
    echo "source /home/$username/.k8s_aliases" >> /home/$username/.bashrc
fi

# Install or remove fzf
if [ -d "/home/$username/.fzf" ]; then
    echo "fzf is already installed for user $username."
    read -p "Do you want to remove fzf? [y/N] " yn
    case $yn in
        [Yy]* )
            sudo -u $username sh -c 'rm -rf ~/.fzf'
            echo "fzf has been removed for user $username."
            sudo -u $username sh -c 'sed -i "/.fzf/d" ~/.bashrc'
            ;;
        * ) ;;
    esac
else
    read -p "Do you want to install fzf for user $username? [y/N] " yn
    case $yn in
        [Yy]* )
            sudo -u $username sh -c 'git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && yes | ~/.fzf/install'
            ;;
        * ) ;;
    esac
fi

echo "Script execution completed successfully!"