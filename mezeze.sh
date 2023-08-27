#!/bin/bash

# Define the directory where the repository is cloned and other related paths
REPO_DIR="/opt/kaltura/mezeze"
SCRIPT_PATH="$REPO_DIR/mezeze.sh"
REMOTE_REPO="https://github.com/PaulRoze/mezeze.git"

# If the CHECK_FOR_UPDATES environment variable is set, use its value. Otherwise, default to true.
CHECK_FOR_UPDATES=${CHECK_FOR_UPDATES:-true}

# Function to check and pull the latest version of the script
check_for_updates() {
    # If the flag is set to false, skip the update check
    if [ "$CHECK_FOR_UPDATES" = false ]; then
        return
    fi

    # Navigate to the script's repository directory
    cd "$REPO_DIR"

    # Fetch the latest commits from the remote repository
    git fetch

    # Check if there are local changes
    if git diff --exit-code; then
        echo "You have local changes in the script."
        read -p "Do you want to discard local changes and update to the latest version? [y/N] " yn_discard
        case $yn_discard in
            [Yy]* )
                # Discard local changes
                git reset --hard
                ;;
            * )
                echo "Update aborted due to local changes."
                return
                ;;
        esac
    fi

    # Check if the local script is behind the remote version
    if git status -uno | grep -q 'Your branch is behind'; then
        echo "A newer version of the script is available."
        read -p "Do you want to update to the latest version? [y/N] " yn_update
        case $yn_update in
            [Yy]* )
                # Pull the latest changes
                git pull
                echo "Script updated. Re-running the updated script..."
                # Re-run the script without checking for updates
                CHECK_FOR_UPDATES=false exec env CHECK_FOR_UPDATES=false "$SCRIPT_PATH"
                exit 0
                ;;
            * )
                echo "Proceeding with the current version of the script."
                ;;
        esac
    fi
}

# Call the function to check for updates
check_for_updates

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
    read -p "Do you want to continue and update the kubeconfig for ${username}? [y/N] " yn
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

# Path to the dedicated Kubernetes alias file
ALIAS_FILE="/home/$username/.k8s_aliases"

# Check if .k8s_aliases already exists
if [ -f "$ALIAS_FILE" ]; then
    echo "Kubernetes aliases file .k8s_aliases already exists for user $username."
    read -p "Do you want to overwrite the existing Kubernetes aliases? [y/N] " yn
    : ${yn:="n"}
    case $yn in
        [Yy]* )
            # Overwrite the kubectl aliases in the dedicated file
            echo '
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
            alias kdd="kd deployment"
            alias kdr="kd rollout"
            alias kdds="kd daemonset"
            alias kgpn="kgp --output=jsonpath={.items..metadata.name}"' > $ALIAS_FILE
            ;;
        * )
            echo "Not overwriting the existing Kubernetes aliases."
            ;;
    esac
else
    # Create the kubectl aliases in the dedicated file
    echo '
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
    alias kdd="kd deployment"
    alias kdr="kd rollout"
    alias kdds="kd daemonset"
    alias kgpn="kgp --output=jsonpath={.items..metadata.name}"' > $ALIAS_FILE
fi

# Check if .bashrc already sources the .k8s_aliases file
if ! sudo -u $username grep -q "source /home/$username/.k8s_aliases" /home/$username/.bashrc; then
    # Add a line in .bashrc to source the .k8s_aliases file
    echo "source /home/$username/.k8s_aliases" >> /home/$username/.bashrc
fi

# Check if fzf is already installed
if [ -d "/home/$username/.fzf" ]; then
    echo "fzf is already installed for user $username."
    read -p "Do you want to remove fzf? [y/N] " yn
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
    read -p "Do you want to install fzf for user $username? [y/N] " yn
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