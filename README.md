# User Creation and Management Bash Script

## Overview
This script automates the creation of users based on input from a specified file. It also sets up home directories, assigns appropriate permissions, generates random passwords, adds the users to specified groups and logs all important actions.

## Requirements
- This script must be run with root privileges.
- Ensure the input file is formatted correctly: each line should contain a username followed by groups, separated by a semicolon (;). Groups should be comma-separated.

### Example Input File
```
light; sudo,dev,www-data
idimma; sudo
mayowa; dev,www-data
```
## Usage
1. Make the script executable:
```
chmod +x create_users.sh
```
2. Run the script with the input file as an argument:
```
sudo ./create_users.sh <user_file>
```
Replace `<user_file>` with the path to your input file.

## Script Details

### Logging and Password Storage
- Log File: /var/log/user_management.log
    - Holds logs of actions performed by the script.
- Password File: /var/secure/user_passwords.csv
    - Stores generated passwords securely.

### Functionality
1. Root Privileges Check: The script verifies it is being run with root privileges.

2. Input File Check: Ensures the input file is provided and properly formatted.

3. User and Group Creation:

    - Creates a user with a home directory and default shell.
    - Creates a personal group for the user if it doesn't exist.
    - Sets up appropriate permissions for the home directory.
    - Adds the user to additional specified groups, creating those groups if they don't exist.
4. Password Generation:

    - Generates a random password for each user.
    - Sets the password and stores it in a secure file.
5. Logging:

    - Logs all actions and any errors encountered.
    - Logs successful completion of user creation.

## Important Notes
- The script must be run as root.
- Ensure the input file follows the specified format to avoid errors.
- Check /var/log/user_management.log for a detailed log of actions and /var/secure/user_passwords.csv for the generated passwords.

## Conclusion
This script automates the tedious process of creating users and groups, setting up directories, and managing passwords. It ensures consistency and security in some user management tasks.

For more details about the [HNG Internship](https://hng.tech/internship) and opportunities, check out the HNG Internship and [HNG Premium](https://hng.tech/premium).