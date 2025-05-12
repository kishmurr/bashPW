#!/bin/bash

# Function to change the master password
change_master_password() {
    read -s -p "Enter current master password: " CURRENT_PASSWORD
    echo
    STORED_PASSWORD=$(cat "$MASTER_KEY_FILE")
    DECODED_STORED_PASSWORD=$(echo "$STORED_PASSWORD" | base64 --decode 2>/dev/null)

    if [ "$CURRENT_PASSWORD" != "$DECODED_STORED_PASSWORD" ]; then
        echo "Incorrect master password."
        return
    fi

    read -s -p "Enter new master password: " NEW_PASSWORD1
    echo
    read -s -p "Confirm new master password: " NEW_PASSWORD2
    echo

    if [ "$NEW_PASSWORD1" != "$NEW_PASSWORD2" ]; then
        echo "New passwords do not match."
        return
    fi

    # Base64 encode the new master password
    ENCODED_NEW_PASSWORD=$(echo -n "$NEW_PASSWORD1" | base64)
    echo "$ENCODED_NEW_PASSWORD" > "$MASTER_KEY_FILE"
    echo "Master password changed successfully."
    # Ensure file permissions are restrictive
    chmod 600 "$MASTER_KEY_FILE"
}


# Define data files
DATA_FILE=".pm_passwords.dat"
MASTER_KEY_FILE=".pm_master_key"

# Check if master password exists, if not, set it up
if [ ! -f "$MASTER_KEY_FILE" ]; then
    echo "Master password not set. Please set a master password:"
    read -s MASTER_PASSWORD_SET
    echo
    # Base64 encode the master password
    ENCODED_MASTER_PASSWORD=$(echo -n "$MASTER_PASSWORD_SET" | base64)
    echo "$ENCODED_MASTER_PASSWORD" > "$MASTER_KEY_FILE"
    echo "Master password set."
    # Ensure file permissions are restrictive
    chmod 600 "$MASTER_KEY_FILE"
fi

# Function to handle login
login() {
    read -s -p "Enter master password: " ENTERED_PASSWORD
    echo
    STORED_PASSWORD=$(cat "$MASTER_KEY_FILE")
    # Base64 decode the stored master password for comparison
    DECODED_STORED_PASSWORD=$(echo "$STORED_PASSWORD" | base64 --decode 2>/dev/null)

    if [ "$ENTERED_PASSWORD" == "$DECODED_STORED_PASSWORD" ]; then
        echo "Login successful!"
        return 0 # Success
    else
        echo "Incorrect password."
        return 1 # Failure
    fi
}

# Function to add a password
add_password() {
    read -p "Enter username: " USERNAME
    read -s -p "Enter password: " PASSWORD
    echo

    if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
        echo "Username or password cannot be empty."
        return
    fi

    # Base64 encode the password
    ENCODED_PASSWORD=$(echo -n "$PASSWORD" | base64)

    # Append to data file (create if it doesn't exist)
    echo "$USERNAME:$ENCODED_PASSWORD" >> "$DATA_FILE"
    echo "Password added successfully."
    # Ensure file permissions are restrictive
    chmod 600 "$DATA_FILE" 2>/dev/null # Ignore error if file doesn't exist yet
}

# Function to read passwords
read_passwords() {
    if [ ! -f "$DATA_FILE" ]; then
        echo "No passwords saved yet."
        return
    fi

    echo "--- Saved Passwords ---"
    while IFS= read -r line; do
        # Skip empty lines
        if [ -z "$line" ]; then
            continue
        fi
        # Split line into username and encoded password
        USERNAME=$(echo "$line" | cut -d':' -f1)
        ENCODED_PASSWORD=$(echo "$line" | cut -d':' -f2)

        # Base64 decode the password
        DECODED_PASSWORD=$(echo "$ENCODED_PASSWORD" | base64 --decode 2>/dev/null)

        echo "Username: $USERNAME"
        echo "Password: $DECODED_PASSWORD"
        echo "-----------------------"
    done < "$DATA_FILE"
}

# Main program loop
if login; then
    while true; do
        echo "Password Manager Menu:"
        echo "1. Add Password"
        echo "2. View Passwords"
        echo "3. Change Master Password"
        echo "4. Quit"
        read -p "Enter your choice: " CHOICE

        case "$CHOICE" in
            1)
                add_password
                ;;
            2)
                read_passwords
                ;;
            3)
                change_master_password
                ;;
            4)
                echo "Exiting Password Manager."
                exit 0
                ;;
            *)
                echo "Invalid choice. Please try again."
                ;;
        esac
        echo # Newline for better readability
    done
fi


