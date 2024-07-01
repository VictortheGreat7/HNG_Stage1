#!/bin/bash

# Script to create users and groups from a file

# Define log and password storage files
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Check if the script is run with root privileges
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run with root privileges." >&2
  exit 1
fi

# Check if the input file is provided
if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <user_file>" >&2
  exit 1
fi

# Log function
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to create user and log actions
create_user() {
  local username="$1"
  local groups="$2"

  # Check if user already exists
  if id "$username" &> /dev/null; then
    log_action "User '$username' already exists. Skipping..."
    return 1
  fi

  # Create user group
  if ! getent group "$username" >/dev/null; then
    groupadd "$username"
    log_action "Group $username created."
  fi

  # Create user with home directory
  useradd -m -g "$username" -s /bin/bash "$username"
  log_action "User $username created."

  # Add user to additional groups (comma separated)
  IFS=',' read -ra group_array <<< "$groups"
  for group in "${group_array[@]}"; do
    group=$(echo "$group" | xargs)
    if ! getent group "$group" >/dev/null; then
      groupadd "$group"
      log_action "Group $group created."
    fi
    gpasswd -a "$username" "$group"
    log_action "User $username added to group $group."
  done

  # Set up home directory permissions
  chmod 700 "/home/$username"
  chown "$username:$username" "/home/$username"
  log_action "Set permissions for /home/$username."

  # Generate random password and set it
  password=$(head /dev/urandom | tr -dc A-Za-z0-9 | fold -w 12 | head -n 1)
  echo "$username:$password" | chpasswd
  echo "$username,$password" >> "$PASSWORD_FILE"
  log_action "Password set for user $username."

  echo "User '$username' created successfully." | tee -a "$LOG_FILE"
}

# Process the user file
user_file="$1"
while IFS=';' read -r username groups; do
  create_user "$username" "${groups%%[ ;]}"  # Remove trailing spaces from groups
done < "$user_file"

log_action "User creation script completed."
echo "User creation script completed. Check $LOG_FILE for details."

# Keep password file accessible only to the owner
chmod 600 "$PASSWORD_FILE"
