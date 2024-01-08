#!/bin/bash

SCRIPT_VERSION="v1.0.3"

# Function to check for script updates
check_for_update() {
    echo "Checking for updates..."
    curl --connect-timeout 10 -s https://raw.githubusercontent.com/PaulRoze/mezeze/main/mezeze.sh -o /tmp/latest_mezeze.sh
    if [ $? -ne 0 ]; then
        read -r -p "Error: Failed to check for updates due to no internet connection. Do you want to proceed? [y/N] " yn
        echo # add a newline for clean output
        case $yn in
            [Yy]* ) return 1;; # Skip update process
            * ) exit 1;;
        esac
    fi
    local latest_version=$(grep '^SCRIPT_VERSION=' /tmp/latest_mezeze.sh | cut -d '"' -f 2)

    if [[ $latest_version > $SCRIPT_VERSION ]]; then
        echo "Current script version: $SCRIPT_VERSION"
        echo "New version available: $latest_version"
        read -r -p "Would you like to update to the latest version? [y/N] " yn
        case $yn in
            [Yy]* ) update_script; return 0;;
            * ) return 1;;
        esac
    else
        echo "You are using the latest version of the script."
        return 1
    fi
}

# Function to update the script
update_script() {
    local script_name=$(basename "$0")
    local temp_script="/tmp/$script_name"

    echo "Downloading the latest version..."
    curl --connect-timeout 10 -s https://raw.githubusercontent.com/PaulRoze/mezeze/main/mezeze.sh -o "$temp_script"
    if [ $? -ne 0 ]; then
        read -r -p "Error: Unable to connect to the internet. Do you want to proceed without updating? [y/N] " yn
        echo # add a newline for clean output
        case $yn in
            [Yy]* ) return 1;; # Skip update process
            * ) exit 1;;
        esac
    fi

    if [ ! -s "$temp_script" ]; then
        read -r -p "Failed to download the update. Proceed without updating? [y/N] " yn
        echo # add a newline for clean output
        case $yn in
            [Yy]* ) return 1;; # Skip update process
            * ) exit 1;;
        esac
    fi

    chmod +x "$temp_script"
    mv "$temp_script" "$0"
    echo "Update completed. Please rerun the script."
    exit 0
}

# Check for updates at the beginning of the script
check_for_update

function usage {
    echo "Usage: $0 <username> <region> <environment>"
    echo ""
    echo "Purpose: This script automates the process of creating a new user, setting up AWS CLI, updating kubeconfig, adding kubectl aliases, and installing fzf."
    echo ""
    echo "Arguments:"
    echo "  <username>: The name of the user to create."
    echo "  <region>: The AWS region where the EKS clusters are located."
    echo "  <environment>: The environment name used to construct EKS cluster names for kubeconfig."
    echo ""
    echo "The script sets up the AWS CLI and updates the kubeconfig for the created user."
    echo ""
    echo "In addition, the script adds several useful kubectl aliases to the created user's .bashrc file."
    echo ""
    echo "Finally, the script also installs and configures fzf, a command-line fuzzy finder, for the created user."
    exit 1
}

# Validate user input
if [[ $1 == "--help" || $1 == "-h" ]]; then
    usage
fi

if [[ $# -lt 1 ]]; then
    echo "Error: Insufficient arguments provided."
    usage
fi

# Ensure the provided username doesn't contain malicious input or commands
if [[ ! "$1" =~ ^[a-zA-Z0-9_\-]+$ ]]; then
    echo "Error: Invalid username. Only alphanumeric characters, underscores, and dashes are allowed."
    exit 1
fi

username=$1
if [ -z "$2" ] ; then
	region=$(ec2-metadata -z| awk '{print $NF}' | sed 's/.$//g')
else
	region=$2
fi
if [ -z "$3" ]; then
	environment=$(ec2-metadata -u | awk -F: '/keyname:/ {print $NF}' | awk -F- '{print $1}')
else
	environment=$3
fi

read -r -p "Running with region [default: ${region}]: " -i ${region} input_region
region=${input_region:-$region}

read -r -p "Running with env [default: ${environment}]: " -i ${environment} input_env
environment=${input_env:-$environment}

echo "Configurations:"
echo "Username: [${username}]"
echo "Environment: [${environment}]"
echo "Region: [${region}]"

# Check if the user already exists
if id "$username" &>/dev/null; then
    echo "User '$username' already exists."
    read -r -p "Do you want to continue and update the kubeconfig for ${username}? [y/N] " yn
    : ${yn:="n"}
    case $yn in
        [Yy]* ) ;;
        * ) exit;;
    esac
else
    # Create the new user
    useradd -m -s /bin/bash "$username" || { echo "Failed to create user '$username'"; exit 1; }
    echo "User '$username' created successfully."
fi

# Check if region is set
if [ -z "$region" ]; then
    echo "Error: AWS region not set. Please set the region by running 'aws configure' or provide it as an argument."
    exit 1
fi

CLUSTER_LIST=$(aws eks list-clusters --query 'clusters[]' --output text --region ${region})
for cluster in $CLUSTER_LIST ; do
    if [[ $cluster == *"$environment"* ]]; then
        sudo -u $username sh -c "PATH=/usr/local/bin:$PATH aws eks update-kubeconfig --name ${cluster} --region ${region}" || echo "Failed to update kubeconfig for ${cluster}"
    fi
done
echo "Kubeconfig updated successfully for user '$username'."

# Define the aliases as a variable
KUBECTL_ALIASES=$(cat <<'EOF'
# kubernetes
alias k="kubectl"
alias kx="/usr/local/bin/kubectx"
alias kn="/usr/local/bin/kubens"
alias ke="kubectl exec -it"
alias kl="kubectl logs"
alias kg="kubectl get"
alias ktn="kubectl top no --use-protocol-buffers"
alias ktp="kubectl top pod --use-protocol-buffers"
alias kd="kubectl describe"
alias kni="kubectl get nodes -o=custom-columns=NODE:.metadata.name,MAX_PODS:.status.allocatable.pods,CAPACITY_PODS:.status.capacity.pods,INSTANCE_TYPE:.metadata.labels.\"node\.kubernetes\.io/instance-type\",ARCH:.status.nodeInfo.architecture,NODE_NAME:.metadata.labels.\"kubernetes\.io/hostname\""
alias kgn="kg nodes"
alias kgp="kg pods"
alias kgpa="kgp -A"
alias kgd="kg deployment"
alias kgr="kg rollout"
alias kdp="kd pods"
alias kdpw="kd pods -o wide"
alias kdd="kd deployment"
alias kdr="kd rollout"
alias kdds="kd daemonset"
alias kgpn="kgp --output=jsonpath={.items..metadata.name}"
EOF
)

# Path to the dedicated Kubernetes alias file
ALIAS_FILE="/home/$username/.bash_aliases_k8s"

# Check if .bash_aliases_k8s already exists
if [ -f "$ALIAS_FILE" ]; then
    echo "Kubernetes aliases file $(basename $ALIAS_FILE) already exists for user $username. at $ALIAS_FILE"
    read -r -p "Do you want to overwrite the existing Kubernetes aliases? [y/N] " yn
    : ${yn:="n"}
    case $yn in
        [Yy]* )
            echo "$KUBECTL_ALIASES" > $ALIAS_FILE
            ;;
        * )
            echo "Not overwriting the existing Kubernetes aliases."
            ;;
    esac
else
    echo "$KUBECTL_ALIASES" > $ALIAS_FILE
fi

# Check if .bashrc already sources the aliase files
for ALIAS_FILE_NAME in .bash_aliases_k8s .bash_aliases; do 
	if ! grep -q "source .*$(basename $ALIAS_FILE_NAME )" /home/$username/.bashrc && test -f /home/$username/$ALIAS_FILE_NAME ; then
	# Add a line in .bashrc to source the .k8s_aliases file
	cat << EOF >> /home/${username}/.bashrc    
# Source aliases
if [ -f "\${HOME}/.$ALIAS_FILE_NAME" ]; then
	source "\${HOME}/$ALIAS_FILE_NAME"
fi
#
EOF
	fi
	chown ${username}: /home/$username/$ALIAS_FILE_NAME
done

# Check if fzf is already installed
if [ -d "/home/$username/.fzf" ]; then
    echo "fzf is already installed for user $username."
    read -r -p "Do you want to remove fzf? [y/N] " yn
    : ${yn:="n"}
    case $yn in
        [Yy]* )
            sudo -u $username sh -c 'rm -rf ~/.fzf'
            echo "fzf has been removed for user $username."
            # Remove all lines in .bashrc related to fzf
            sudo -u $username sh -c 'sed -i "/.fzf/d" ~/.bashrc'
            ;;
        * ) ;;
    esac
else
    read -r -p "Do you want to install fzf for user $username? [y/N] " yn
    : ${yn:="n"}
    case $yn in
        [Yy]* )
            # Install fzf for the user
            sudo -u $username sh -c 'git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && yes | ~/.fzf/install'
            ;;
        * ) ;;
    esac
fi

echo "Script execution completed successfully!"
