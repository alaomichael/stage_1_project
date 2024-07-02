### Technical Article

#### Creating Linux Users with Bash Script: A Step-by-Step Guide

Managing users in a Linux environment can be a challenging task, especially when dealing with a large number of users. Automation using Bash scripts can streamline this process. In this article, we will walk you through a Bash script designed to automate the creation of users, setup home directories, assign groups, and generate passwords, while maintaining logs and securing sensitive information.

**[HNG Internship](https://hng.tech/internship) | [Hire from HNG](https://hng.tech/hire)**

#### Script Overview

The script, `create_users.sh`, reads a text file containing usernames and groups, creates the users, assigns them to the specified groups, sets up their home directories, generates random passwords, and logs all actions. Additionally, the generated passwords are stored securely.

#### Script Breakdown

1. **Input Validation**:
   ```bash
   if [ $# -ne 1 ]; then
       echo "Usage: $0 <name-of-text-file>"
       exit 1
   fi
   ```
   The script starts by checking if the correct number of arguments is provided. It expects one argument - the name of the text file.

2. **Setting Up Log and Password Files**:
   ```bash
   LOG_FILE="/var/log/user_management.log"
   PASSWORD_FILE="/var/secure/user_passwords.csv"
   
   touch $LOG_FILE
   chmod 600 $LOG_FILE
   
   mkdir -p /var/secure
   touch $PASSWORD_FILE
   chmod 600 $PASSWORD_FILE
   ```
   Log and password files are created with restricted permissions to ensure security.

3. **Logging Function**:
   ```bash
   log_action() {
       echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
   }
   ```
   This function logs messages with timestamps to the log file.

4. **Reading and Processing Input File**:
   ```bash
   while IFS=';' read -r username groups; do
       username=$(echo "$username" | xargs)
       groups=$(echo "$groups" | xargs)
   ```
   The script reads the input file line by line, processing each username and their respective groups.

5. **User and Group Creation**:
   ```bash
   if id "$username" &>/dev/null; then
       log_action "User $username already exists."
       continue
   fi
   
   groupadd "$username"
   log_action "Group $username created."
   
   useradd -m -g "$username" -G "$(echo $groups | tr ',' ' ')" "$username"
   log_action "User $username created and added to groups: $groups."
   ```
   It checks if the user already exists. If not, it creates a personal group for the user and then the user itself, assigning them to the specified groups.

6. **Password Generation and Assignment**:
   ```bash
   password=$(openssl rand -base64 12)
   echo "$username:$password" | chpasswd
   log_action "Password set for user $username."
   echo "$username,$password" >> $PASSWORD_FILE
   ```
   A random password is generated for the user, set, and stored securely.

7. **Setting Permissions**:
   ```bash
   chown "$username:$username" "/home/$username"
   chmod 700 "/home/$username"
   log_action "Home directory for $username set with appropriate permissions and ownership."
   ```
   The script sets appropriate permissions for the user's home directory.

8. **Completion Log**:
   ```bash
   log_action "User creation script completed."
   ```

This script ensures a systematic, secure, and efficient way of managing user creation in a Linux environment.

For more information on how to automate such tasks and streamline your workflows, check out the [HNG Internship](https://hng.tech/internship) program, where you can enhance your skills and gain valuable experience. You can also explore opportunities to [hire top talents](https://hng.tech/hire) from HNG.

### Conclusion

Automating user management in Linux with Bash scripts not only saves time but also ensures consistency and security. By following the steps outlined in this article, you can easily set up a robust user management system tailored to your organization's needs.

---

Feel free to adapt this script to your specific requirements and ensure you test it in a safe environment before deploying it to production. Happy scripting!