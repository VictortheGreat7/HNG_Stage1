#!/bin/bash

# Script to create users and groups provided in a file

# Define log and password storage files
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Check if the script is run with root privileges
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run with root privileges." >&2
  exit 1
fi

# Check if the input file is provided
if [[ $# -eq 0 || $# -ge 2 ]]; then
  echo "Usage: $0 <user_file>" >&2
  exit 1
fi

# Log function
log_action() {
  echo "--------------------------------------------------" | tee -a "$LOG_FILE"
  echo -e "$(date +'%Y-%m-%d %H:%M:%S') - \033[1m$1\033[0m" | tee -a "$LOG_FILE"
  echo "--------------------------------------------------" | tee -a "$LOG_FILE"
}

# Function to create user and log actions
create_user_account() {
  local username="$1"
  local groups="$2"

  log_action "Creating user account '$username'..."
  
  # Check if user already exists
  if id "$username" &> /dev/null; then
    echo "User '$username' already exists. Skipping..." | tee -a "$LOG_FILE"
    return 1
  fi

  # Create user with home directory and set shell
  if useradd -m -s /bin/bash "$username"; then
    echo "User $username created successfully." | tee -a "$LOG_FILE"
  else
    echo "Error creating user $username." | tee -a "$LOG_FILE"
    return 1
  fi

  # Create user group if it does not exist (in case the script is run in other linux distributions that do not create user groups by default)
  if ! getent group "$username" >/dev/null; then
    groupadd "$username"
    usermod -g "$username" "$username"
    log_action "Group $username created."
  fi

  # Set up home directory permissions
  echo "Setting permissions for /home/$username..." | tee -a "$LOG_FILE"
  chmod 700 "/home/$username" && chown "$username:$username" "/home/$username"
  if [[ $? -eq 0 ]]; then
    echo "Permissions set for /home/$username." | tee -a "$LOG_FILE"
  else
    echo "Error setting permissions for /home/$username." | tee -a "$LOG_FILE"
    return 1
  fi

  # Add user to additional groups (comma separated)
  echo "Adding user $username to specified additional groups..." | tee -a "$LOG_FILE"
  IFS=',' read -ra group_array <<< "$groups"
  for group in "${group_array[@]}"; do
    group=$(echo "$group" | xargs)
    
    # Check if group exists, if not create it
    if ! getent group "$group" &>/dev/null; then
      if groupadd "$group"; then
        echo "Group $group did not exist. Now created." | tee -a "$LOG_FILE"
      else
        echo "Error creating group $group." | tee -a "$LOG_FILE"
        continue
      fi
    fi

    # Add user to group
    if gpasswd -a "$username" "$group"; then
      echo "User $username added to group $group." | tee -a "$LOG_FILE"
    else
      echo "Error adding user $username to group $group." | tee -a "$LOG_FILE"
    fi
  done

  # Log if no additional groups are specified
  if [[ -z "$groups" ]]; then
    echo "No additional groups specified." | tee -a "$LOG_FILE"
  fi

  # Generate random password, set it for the user, and store it in a file
  echo "Setting password for user $username..." | tee -a "$LOG_FILE"
  password=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 12)
  echo "$username:$password" | chpasswd
  if [[ $? -eq 0 ]]; then
    echo "Password set for user $username." | tee -a "$LOG_FILE"
    echo "$username,$password" >> "$PASSWORD_FILE"
  else
    echo "Error setting password for user $username. Deleting $username user account" | tee -a "$LOG_FILE"
    userdel -r "$username"
    return 1
  fi
}

# Process the user file
user_file="$1"
while IFS=';' read -r username groups; do
  if create_user_account "$username" "${groups%%[ ;]}"; then
    log_action "User account '$username' created successfully."
  else
    log_action "Error creating user account '$username'."
  fi
done < "$user_file"

# Keep password file accessible only to those with root privileges
chmod 600 "$PASSWORD_FILE"

# Log completion
log_action "User creation script completed."

# Print log file and password file location
echo "Check $LOG_FILE for details."
echo "Check $PASSWORD_FILE for user passwords."
