# Mezeze

## Overview
Mezeze is a Bash script designed for AWS and Kubernetes environment management, including automated user creation, AWS CLI configuration, kubeconfig updates, kubectl aliases setup, and fzf installation.
## Features

### Script Functionalities
- **User Creation and Setup:** Automates the creation of a new user and configures their environment for AWS and Kubernetes.
- **AWS CLI Configuration:** Sets up the AWS CLI for the newly created user.
- **Kubeconfig Management:** Automatically updates kubeconfig for specified EKS clusters.
- **Kubectl Aliases:** Adds useful kubectl aliases to the user's `.bashrc`.
- **FZF Installation:** Installs fzf, a command-line fuzzy finder.

### Automated Update Checks
- The script checks for its latest version at startup and prompts for an update if a newer version is available.

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
**_You can provide only username, and the script will prompt for the rest of the values._**

3. **Update Prompt:**
The script will prompt for updates if a new version is available.

## Script Help
To access the help menu for detailed usage instructions, run:
```
./mezeze.sh --help
```

## Logic Flow

graph TD
    A[Start Script] --> B[Check for updates]
    B -->|Update Available| C[Ask to Update]
    B -->|No Update| D1[Validate '--help' or '-h']
    C -->|Yes to Update| E[Update Script]
    C -->|No Update| D1
    E --> F[Exit after Update]
    D1 -->|Help Requested| D2[Show Usage and Exit]
    D1 -->|No Help Request| D3[Check Argument Count]
    D3 -->|Insufficient Args| D2
    D3 -->|Valid Args| D4[Validate Username Format]
    D4 -->|Invalid Username| I[Error: Invalid Username and Exit]
    D4 --> J[Set Username, Region, Environment]
    J --> K[Check if User Exists]
    K -->|User Exists| L[Ask to Update kubeconfig]
    K -->|New User| M[Create New User]
    L -->|Yes to Update kubeconfig| N[Continue]
    L -->|No Update| O[Exit]
    M --> N
    N --> P[Check if Region is Set]
    P -->|Region Not Set| Q[Error: Region Not Set and Exit]
    P --> R[Update kubeconfig for EKS Clusters]
    R --> S1[Check Kubernetes Aliases File]
    S1 -->|File Exists| S2[Ask to Overwrite Aliases]
    S1 -->|No File| S3[Create Aliases File]
    S2 -->|Yes to Overwrite| S3
    S2 -->|No Overwrite| S4[Skip Alias Creation]
    S3 --> S4[Alias File Created or Updated]
    S4 --> T1[Check if .bashrc Sources .k8s_aliases]
    T1 -->|Not Sourced| T2[Update .bashrc]
    T1 -->|Already Sourced| T3[Skip .bashrc Update]
    T2 --> T3[.bashrc Updated]
    T3 --> U1[Check if fzf Installed]
    U1 -->|fzf Installed| U2[Ask to Remove fzf]
    U1 -->|fzf Not Installed| U3[Ask to Install fzf]
    U2 -->|Yes to Remove| U4[Remove fzf and Update .bashrc]
    U2 -->|No Removal| U5[Skip fzf Changes]
    U3 -->|Yes to Install| U6[Install fzf and Update .bashrc]
    U3 -->|No Install| U5
    U4 --> U5[fzf Removed]
    U6 --> U5[fzf Installed]
    U5 --> V[Script Execution Completed]

## Sequence Diagram

sequenceDiagram
    participant S as Script
    participant U as User
    participant F as Functions

    S->>S: Start
    S->>F: Check for Updates
    alt Update Available
        F->>U: Prompt for Update
        U->>F: User Choice
        F->>S: Update Script
        S->>S: Exit
    else No Update
        S->>F: Validate Input
        F->>U: Get User Input
        U->>F: Input Provided
        alt Valid Input
            F->>S: Set Parameters
            S->>F: Check User Existence
            alt User Exists
                F->>S: Update kubeconfig
            else New User
                F->>S: Create User
            end
            S->>S: Script Completion
        else Invalid Input
            F->>S: Show Usage and Exit
        end
    end

## Contributing
Contributions to Mezeze are welcome. To contribute:

1. Fork the repository.
2. Create a feature branch.
3. Commit and push your changes.
4. Open a pull request against the `main` branch.


## Issues and Support
For issues, feature requests, or assistance, please open an issue in the repository.

## License
This project is released under the [MIT License](LICENSE).
