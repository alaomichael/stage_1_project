#!/bin/bash

# Check if the file argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <name-of-text-file>"
    exit 1
fi

INPUT_FILE=$1
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Create log file and set permissions
touch $LOG_FILE
chmod 600 $LOG_FILE

# Create password file and set permissions
mkdir -p /var/secure
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

# Function to log messages
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Read the input file line by line
while IFS=';' read -r username groups; do
    username=$(echo "$username" | xargs) # Remove leading/trailing whitespace
    groups=$(echo "$groups" | xargs)     # Remove leading/trailing whitespace

    if id "$username" &>/dev/null; then
        log_action "User $username already exists."
        continue
    fi

    # Create the user's personal group
    groupadd "$username"
    log_action "Group $username created."

    # Create the user and their home directory
    useradd -m -g "$username" -G "$(echo $groups | tr ',' ' ')" "$username"
    log_action "User $username created and added to groups: $groups."

    # Generate a random password
    password=$(openssl rand -base64 12)

    # Set the user's password
    echo "$username:$password" | chpasswd
    log_action "Password set for user $username."

    # Store the username and password securely
    echo "$username,$password" >> $PASSWORD_FILE

    # Set appropriate permissions and ownership
    chown "$username:$username" "/home/$username"
    chmod 700 "/home/$username"
    log_action "Home directory for $username set with appropriate permissions and ownership."

done < "$INPUT_FILE"

log_action "User creation script completed."
