#!/bin/bash

# Set the password file
SCRIPT_DIR="$(dirname "$0")"
PASSWORD_FILE="$SCRIPT_DIR/.passwords.txt"
MASTER_PASSWORD_FILE="$SCRIPT_DIR/.master_password.txt"

# Function to generate a random password
generate_password() {
  local length=${1:-16} # Default length is 16
  tr -dc A-Za-z0-9_ <<< $(head /dev/urandom | tr -dc A-Za-z0-9_ | head -c ${length})
}

# Function to set the master password
set_master_password() {
  read -s -p "Enter new master password: " master_password
  echo
  read -s -p "Confirm new master password: " confirm_password
  echo

  if [ "$master_password" != "$confirm_password" ]; then
    echo "Passwords do not match. Please try again."
    return 1
  fi

  # Store the master password (hash it first!)
  MASTER_PASSWORD_HASHED=$(echo -n "$master_password" | sha256sum | awk '{print $1}')
  echo "Master password set."

  # Store the hashed password in a file (not recommended for real security)
  touch "$MASTER_PASSWORD_FILE"
  chmod 600 "$MASTER_PASSWORD_FILE" # Make it readable only by the user
  echo "$MASTER_PASSWORD_HASHED" > "$MASTER_PASSWORD_FILE"
  unset master_password confirm_password
  return 0
}

# Function to check the master password
check_master_password() {
if [ ! -f "$MASTER_PASSWORD_FILE" ]; then
echo "Master password not set. Please set it now."
set_master_password
return 1
fi
stored_password=$(cat "$MASTER_PASSWORD_FILE")

read -s -p "Enter master password: " master_password
echo
hashed_password=$(echo -n "$master_password" | sha256sum | awk '{print $1}')

  if [ "$hashed_password" == "$stored_password" ]; then
    MASTER_PASSWORD_HASHED="$hashed_password"
    return 0 # Correct password
  else
    echo "Incorrect master password."
    return 1 # Incorrect password
  fi
}

# Function to add a new password
add_password() {
  read -p "Enter username: " username

  # Generate a password or let the user enter one
  read -p "Generate password? (y/n) [y]: " generate
  if [[ "$generate" == "n" ]]; then
    read -s -p "Enter password: " password
    echo
  else
    password=$(generate_password)
    echo "Generated password: $password"
  fi

  # Encrypt the password entry (very basic "encryption")
  encrypted_entry=$(echo -n "$username:$password" | openssl enc -aes-256-cbc -salt -pass "file:$MASTER_PASSWORD_FILE")

  # Append the encrypted entry to the password file
  echo "$encrypted_entry" >> "$PASSWORD_FILE"
  echo "Password added for $username."
  unset username password encrypted_entry
}

# Function to retrieve a password
get_password() {
  if [ ! -f "$PASSWORD_FILE" ]; then
    echo "No passwords stored yet."
    return 0
  fi

  echo "Stored Passwords:"
  cat "$PASSWORD_FILE" | while read -r encrypted_entry; do
    decrypted_entry=$(echo "$encrypted_entry" | openssl enc -d -aes-256-cbc -salt -pass "file:$MASTER_PASSWORD_FILE" 2>/dev/null)
        if [ -n "$decrypted_entry" ]; then
          IFS=":" read -r username password <<< "$decrypted_entry"
          echo "Username: $username"
          echo "Password: $password"
          echo "---"
        else
            echo "Decryption failed for entry."
        fi
  done
}

# Main menu
main_menu() {
  while true; do
    echo
    echo "Password Manager Menu:"
        echo "1. Set Master Password"
        echo "2. Add Password"
        echo "3. Get Password"
        echo "4. Exit"
        read -p "Enter your choice: " choice

    case "$choice" in
      1)
        set_master_password
        ;;
      2)
          add_password
        ;;
      3)
          get_password
        ;;
      4)
      echo "Exiting."
      exit 0
      ;;
      *)
        echo "Invalid choice. Please try again."
            ;;
        esac
      done
    }

  # Check if master password is set and valid
if [ ! -f "$MASTER_PASSWORD_FILE" ]; then
  echo "Master password not set. Please set it now."
  set_master_password
else
  if ! check_master_password; then
    echo "Exiting due to incorrect master password."
    exit 1
  fi
fi

# Run the main menu
main_menu
```
