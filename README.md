# Automating Linux User Management with Bash

As a SysOps engineer, one of your responsibilities is to efficiently manage user accounts on Linux systems. With the influx of new developers, creating and managing user accounts manually can be time-consuming and prone to errors. To streamline this process, we’ll create a Bash script that automates the creation of users and groups, sets up home directories with appropriate permissions, generates random passwords, and logs all actions for auditing purposes.

## Introduction

Managing user accounts on Linux involves several repetitive tasks, such as creating user accounts, setting up groups, and ensuring appropriate permissions. Automating these tasks can save time and reduce errors. In this article, we'll walk through a Bash script that reads a list of usernames and groups from a text file, creates the necessary users and groups, sets up home directories, generates random passwords, and logs all actions.

## Prerequisites

To follow along, you’ll need:
- A Linux environment (we'll use Ubuntu on Windows Subsystem for Linux (WSL)).
- Visual Studio Code with the Remote - WSL extension.
- Basic knowledge of Bash scripting.

## The Script

Here's the `create_users.sh` script:

```bash
#!/bin/bash

LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"
INPUT_FILE="$1"

# Ensure the log file exists
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

# Ensure the secure directory and password file exist
mkdir -p /var/secure
touch "$PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to create users and groups
create_user() {
    local username=$1
    local groups=$2

    # Check if user already exists
    if id "$username" &>/dev/null; then
        log_message "User $username already exists. Skipping user creation."
        return 1
    fi

    # Create a group with the same name as the user
    if ! getent group "$username" &>/dev/null; then
        groupadd "$username"
        log_message "Group $username created."
    fi

    # Create the user and add to their own group
    useradd -m -g "$username" -s /bin/bash "$username"
    log_message "User $username created."

    # Add user to additional groups
    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        if getent group "$group" &>/dev/null; then
            usermod -aG "$group" "$username"
            log_message "Added $username to group $group."
        else
            log_message "Group $group does not exist. Skipping."
        fi
    done

    # Set a random password
    password=$(openssl rand -base64 12)
    echo "$username:$password" | chpasswd
    log_message "Password set for user $username."

    # Store the username and password in the secure file
    echo "$username,$password" >> "$PASSWORD_FILE"
    log_message "Stored password for user $username."

    # Set the home directory permissions
    chown "$username:$username" "/home/$username"
    chmod 700 "/home/$username"
    log_message "Home directory for $username set with appropriate permissions and ownership."
}

# Process each line in the input file
while IFS=';' read -r username groups; do
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)
    create_user "$username" "$groups"
done < "$INPUT_FILE"

log_message "User creation script completed."
```

### How It Works

1. **Logging Setup**: The script starts by setting up log and password files with appropriate permissions.
2. **User and Group Creation**: For each user, the script checks if the user and their group exist before creating them. It ensures that each user has a group with the same name and adds the user to any additional groups specified.
3. **Password Generation**: A random password is generated using `openssl` and assigned to the user.
4. **Home Directory Setup**: The script sets the ownership and permissions of the user’s home directory.
5. **Logging Actions**: All actions, including errors, are logged to `/var/log/user_management.log`.

Let's break down the `create_users.sh` script step by step to understand each part of the code and its purpose.

### Script Breakdown

#### 1. Shebang and Variable Definitions

```bash
#!/bin/bash

LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"
INPUT_FILE="$1"
```

- `#!/bin/bash`: This is the shebang line that tells the system to use the Bash shell to interpret the script.
- `LOG_FILE`: Defines the path to the log file where actions will be logged.
- `PASSWORD_FILE`: Defines the path to the file where user passwords will be securely stored.
- `INPUT_FILE`: Captures the first argument passed to the script, which is the name of the text file containing usernames and groups.

#### 2. Ensure Log and Password Files Exist

```bash
# Ensure the log file exists
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

# Ensure the secure directory and password file exist
mkdir -p /var/secure
touch "$PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"
```

- `touch "$LOG_FILE"`: Creates the log file if it doesn't already exist.
- `chmod 644 "$LOG_FILE"`: Sets permissions for the log file so it is readable by all users but writable only by the owner.
- `mkdir -p /var/secure`: Creates the `/var/secure` directory if it doesn't exist.
- `touch "$PASSWORD_FILE"`: Creates the password file if it doesn't exist.
- `chmod 600 "$PASSWORD_FILE"`: Sets permissions for the password file so only the owner can read and write it.

#### 3. Logging Function

```bash
# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}
```

- `log_message()`: A function that takes a message as an argument and appends it to the log file with a timestamp.
- `echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"`: Formats the log message with a timestamp and writes it to the log file.

#### 4. User and Group Creation Function

```bash
# Function to create users and groups
create_user() {
    local username=$1
    local groups=$2

    # Check if user already exists
    if id "$username" &>/dev/null; then
        log_message "User $username already exists. Skipping user creation."
        return 1
    fi

    # Create a group with the same name as the user
    if ! getent group "$username" &>/dev/null; then
        groupadd "$username"
        log_message "Group $username created."
    fi

    # Create the user and add to their own group
    useradd -m -g "$username" -s /bin/bash "$username"
    log_message "User $username created."

    # Add user to additional groups
    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        if getent group "$group" &>/dev/null; then
            usermod -aG "$group" "$username"
            log_message "Added $username to group $group."
        else
            log_message "Group $group does not exist. Skipping."
        fi
    done

    # Set a random password
    password=$(openssl rand -base64 12)
    echo "$username:$password" | chpasswd
    log_message "Password set for user $username."

    # Store the username and password in the secure file
    echo "$username,$password" >> "$PASSWORD_FILE"
    log_message "Stored password for user $username."

    # Set the home directory permissions
    chown "$username:$username" "/home/$username"
    chmod 700 "/home/$username"
    log_message "Home directory for $username set with appropriate permissions and ownership."
}
```

- `create_user()`: A function to create a user and their groups.
- `local username=$1` and `local groups=$2`: Capture the username and groups as local variables.
- `if id "$username" &>/dev/null; then`: Check if the user already exists using the `id` command.
- `if ! getent group "$username" &>/dev/null; then`: Check if the user's primary group exists.
- `groupadd "$username"`: Create the primary group for the user.
- `useradd -m -g "$username" -s /bin/bash "$username"`: Create the user with a home directory and set their shell to Bash.
- `IFS=',' read -ra group_array <<< "$groups"`: Split the groups string into an array.
- `for group in "${group_array[@]}"; do`: Loop through each group in the array.
- `usermod -aG "$group" "$username"`: Add the user to each additional group.
- `password=$(openssl rand -base64 12)`: Generate a random password using `openssl`.
- `echo "$username:$password" | chpasswd`: Set the user's password.
- `echo "$username,$password" >> "$PASSWORD_FILE"`: Store the username and password in the secure file.
- `chown "$username:$username" "/home/$username"` and `chmod 700 "/home/$username"`: Set ownership and permissions for the user's home directory.

#### 5. Process Each Line in the Input File

```bash
# Process each line in the input file
while IFS=';' read -r username groups; do
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)
    create_user "$username" "$groups"
done < "$INPUT_FILE"

log_message "User creation script completed."
```

- `while IFS=';' read -r username groups; do`: Read each line in the input file, splitting the line into `username` and `groups` using `;` as the delimiter.
- `username=$(echo "$username" | xargs)` and `groups=$(echo "$groups" | xargs)`: Trim any leading or trailing whitespace from `username` and `groups`.
- `create_user "$username" "$groups"`: Call the `create_user` function for each user and their groups.
- `log_message "User creation script completed."`: Log the completion of the script.

----

### Testing the Script

To test the script on a Windows machine using WSL and VS Code, follow these steps:

1. **Set Up WSL**:
   - Install WSL and a Linux distribution (e.g., Ubuntu) as described in the [WSL installation guide](https://docs.microsoft.com/en-us/windows/wsl/install).

2. **Install VS Code and WSL Extension**:
   - Download and install [Visual Studio Code](https://code.visualstudio.com/).
   - Install the Remote - WSL extension from the Extensions view in VS Code.

3. **Create Project Directory and Files**:
   - Open a WSL terminal in VS Code and create a project directory:
     ```bash
     mkdir create_users_project
     cd create_users_project
     ```
   - Create the `create_users.sh` script and `users.txt` file in this directory.

4. **Make the Script Executable**:
   ```bash
   chmod +x create_users.sh
   ```

5. **Run the Script**:
   ```bash
   sudo ./create_users.sh users.txt
   ```

6. **Verify Results**:
   - Check the log file:
     ```bash
     cat /var/log/user_management.log
     ```
   - Check the password file:
     ```bash
     cat /var/secure/user_passwords.csv
     ```
---

### Conclusion

This script automates the process of creating users, assigning them to groups, generating passwords, and setting up home directories. By logging all actions and securely storing passwords, it ensures transparency and security in user management.