# Mezeze

![GitHub License](https://img.shields.io/github/license/PaulRoze/mezeze)
![GitHub release (with filter)](https://img.shields.io/github/v/release/PaulRoze/mezeze)
![GitHub top language](https://img.shields.io/github/languages/top/PaulRoze/mezeze)
![GitHub file size in bytes on a specified ref (branch/commit/tag)](https://img.shields.io/github/size/PaulRoze/mezeze/mezeze.sh?label=mezeze.sh)

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

Before you begin, ensure you have the following installed and configured on your system:

1. **Bash**: A Unix shell and command language. Available by default on Linux and macOS. [More about Bash](https://www.gnu.org/software/bash/).

2. **Curl**: A command-line tool for transferring data with URLs. [Installing Curl](https://curl.se/download.html).

3. **AWS CLI**: The Amazon Web Services Command Line Interface is used for interacting with AWS services. 
   - Installation: [Installing the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).
   - Configuration: [Configuring the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).

4. **Kubectl**: A command-line tool for controlling Kubernetes clusters. 
   - Installation: [Installing kubectl](https://kubernetes.io/docs/tasks/tools/).
   - Ensure that it's configured to interact with your Kubernetes cluster.

5. **Git**: Required for cloning the repository and managing versions.
   - [Git Installation Guide](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).

6. **Internet Connection**: Required for downloading necessary files, updates, and interacting with remote services like AWS and Kubernetes clusters.

### Optional:

- **EC2 Metadata Tool**: If you are running the script on an AWS EC2 instance, this tool is used to fetch AWS region and environment information. Typically, it's pre-installed on AWS EC2 instances.

### Note:
- Ensure that your user account has the necessary permissions to perform operations like installing software, configuring AWS CLI, and managing Kubernetes clusters.


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

3. **Update Prompt:**
The script will prompt for updates if a new version is available.

## Script Help
To access the help menu for detailed usage instructions, run:
```
./mezeze.sh --help
```

## Logic Flow
```mermaid
graph TD
    A[Start Script] --> B[Check for updates]
    B -->|Update Available| C[Ask to Update]
    B -->|No Update or Unable to Connect| D1[Validate '--help' or '-h']
    C -->|Yes to Update| E[Attempt Update Script]
    C -->|No Update| D1
    E -->|Update Failed or Unable to Connect| F[Ask to Proceed Without Update]
    E -->|Update Successful| G[Exit after Update]
    F -->|Proceed| D1
    F -->|Exit| H[Exit Script]
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
```
## Sequence Diagram
```mermaid
sequenceDiagram
    participant S as Script
    participant U as User
    participant F as Functions

    S->>S: Start
    S->>F: Check for Updates
    alt Update Available
        F->>U: Prompt for Update
        U->>F: User Choice
        alt Yes to Update
            F->>S: Attempt Update Script
            alt Update Successful
                S->>S: Exit
            else Update Failed or Unable to Connect
                F->>U: Ask to Proceed Without Update
                U->>F: User Decision
                alt Proceed
                    S->>F: Validate Input
                else Exit
                    S->>S: Exit Script
                end
            end
        else No Update
            S->>F: Validate Input
        end
    else No Update or Unable to Connect
        S->>F: Validate Input
    end
    F->>U: Get User Input
    alt Valid Input
        U->>F: Input Provided
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
```
## Issues and Support
For issues, feature requests, or assistance, please open an issue in the repository.
* Report by [opening a new issue](https://github.com/PaulRoze/mezeze/issues/new); it's that easy!

🌌 **Crafting the Perfect Bug Report in Mezeze's Universe**:

1. **Quick Summary**: Start with a brief overview. Set the stage for the issue you encountered.

2. **Reproduction Steps**:
   - Clearly list steps to recreate the bug.
   - Include code samples if you have them; they're like secret maps to the bug.

3. **Expectation vs. Reality**:
   - What you thought would happen.
   - What actually happened.

4. **Extra Notes**:
   - Any theories or fixes you tried? Share them! They help in our cloud journey.

Simple, clear reports help us make Mezeze even better for navigating the clouds!


## License
This project is released under the [MIT License](LICENSE).

## Acknowledgements

<!-- readme: collaborators,contributors -start -->
<table>
<tr>
    <td align="center">
        <a href="https://github.com/PaulRoze">
            <img src="https://avatars.githubusercontent.com/u/111685920?v=4" width="60;" alt="PaulRoze"/>
            <br />
            <sub><b>Pavel Rozentsvet</b></sub>
        </a>
    </td></tr>
</table>
<!-- readme: collaborators,contributors -end -->
