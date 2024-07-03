#!/bin/bash

LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"
INPUT_FILE="$1"

# Ensure the log file exists
sudo touch "$LOG_FILE"
sudo chmod 644 "$LOG_FILE"

# Ensure the secure directory and password file exist
sudo mkdir -p /var/secure
sudo touch "$PASSWORD_FILE"
sudo chmod 600 "$PASSWORD_FILE"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOG_FILE"
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
        sudo groupadd "$username"
        log_message "Group $username created."
    fi

    # Create the user and add to their own group
    sudo useradd -m -g "$username" -s /bin/bash "$username"
    log_message "User $username created."

    # Add user to additional groups
    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        if ! getent group "$group" &>/dev/null; then
            sudo groupadd "$group"
            log_message "Group $group created."
        fi
        sudo usermod -aG "$group" "$username"
        log_message "Added $username to group $group."
    done

    # Set a random password
    password=$(openssl rand -base64 12)
    echo "$username:$password" | sudo chpasswd
    log_message "Password set for user $username."

    # Store the username and password in the secure file
    echo "$username,$password" | sudo tee -a "$PASSWORD_FILE" > /dev/null
    log_message "Stored password for user $username."

    # Set the home directory permissions
    sudo chown "$username:$username" "/home/$username"
    sudo chmod 700 "/home/$username"
    log_message "Home directory for $username set with appropriate permissions and ownership."
}

# Read input file and process each line
while IFS=';' read -r username groups || [ -n "$username" ]; do
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)
    create_user "$username" "$groups"
done < "$INPUT_FILE"

log_message "User creation script completed."
