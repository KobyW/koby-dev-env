###                                           ###
#                                               #
# THIS FILE IS FOR CUSTOM SSH RELATED FUNCTIONS #
#                                               #
###                                           ###

#### Create ssh keys fast ####
ssh-create-key() {
    # Prompt for using default email
    read "use_default_email?Use default email (default@example.com)? (yes/no): "
    if [[ "$use_default_email" == "yes" ]]; then
        email="default@example.com"
    else
        read "email?Enter your email: "
    fi

    # Prompt for using default path
    read "use_default_path?Use default path ($HOME/.ssh)? (yes/no): "
    if [[ "$use_default_path" == "yes" ]]; then
        read "key_name?Enter the key name: "
        key_path="$HOME/.ssh/$key_name"
    else
        read "key_path?Enter the full path and name for the key: "
    fi

    # Generate the SSH key
    echo "ssh-keygen -t rsa -b 4096 -C \"$email\" -f \"$key_path\""
    ssh-keygen -t rsa -b 4096 -C "$email" -f "$key_path"
    echo "ssh-keygen complete."
    echo "Used email: $email"
    echo "Key path: $key_path"

    # Ask if the user wants to cd to the path
    read "cd_to_path?Do you want to cd to the key path? (yes/no): "
    if [[ "$cd_to_path" == "yes" ]]; then
        cd "$(dirname "$key_path")"
    else
        # Ask if the user wants to copy the pub or priv key to the clipboard
        read "copy_to_clipboard?Do you want to copy the pub or priv key to the clipboard? (pub/priv/no): "
        if [[ "$copy_to_clipboard" == "pub" ]]; then
            xclip -sel clip < "${key_path}.pub"
            echo "Public key copied to clipboard."
        elif [[ "$copy_to_clipboard" == "priv" ]]; then
            xclip -sel clip < "$key_path"
            echo "Private key copied to clipboard."
        fi
    fi

    # Ask if the user wants to send the key to a server
    read "send_to_server?Do you want to send the key to a server? (yes/no): "
    if [[ "$send_to_server" == "yes" ]]; then
        read "server_address?Enter the server address (user@hostname): "
        read "use_ssh_key?Do you need to specify an SSH key for the scp command? (yes/no): "
        if [[ "$use_ssh_key" == "yes" ]]; then
            read "ssh_key_path?Enter the path to the SSH key: "
        fi

        read "send_both?Do you want to send both the priv and pub keys? (yes/no): "
        if [[ "$send_both" == "yes" ]]; then
            if [[ "$use_ssh_key" == "yes" ]]; then
                scp -i "$ssh_key_path" "$key_path" "$server_address:~/"
                scp -i "$ssh_key_path" "${key_path}.pub" "$server_address:~/"
            else
                scp "$key_path" "$server_address:~/"
                scp "${key_path}.pub" "$server_address:~/"
            fi
            echo "Both private and public keys sent to $server_address."
        else
            read "which_key?Which key do you want to send? (pub/priv): "
            if [[ "$which_key" == "pub" ]]; then
                if [[ "$use_ssh_key" == "yes" ]]; then
                    scp -i "$ssh_key_path" "${key_path}.pub" "$server_address:~/"
                else
                    scp "${key_path}.pub" "$server_address:~/"
                fi
                echo "Public key sent to $server_address."
            elif [[ "$which_key" == "priv" ]]; then
                if [[ "$use_ssh_key" == "yes" ]]; then
                    scp -i "$ssh_key_path" "$key_path" "$server_address:~/"
                else
                    scp "$key_path" "$server_address:~/"
                fi
                echo "Private key sent to $server_address."
            fi
        fi
    fi
}

##### Send one or more SSH key to other server(s) ####
function sendsshkeys() {
    local default_path="$HOME/.ssh"
    local keys_dir
    local selected_keys=()
    local target_servers=()
    local ssh_passphrase=""

    # Ask user for the source path
    echo -n "Do you want to use the default source path ($default_path)? (y/n): "
    read use_default
    if [[ "$use_default" == "y" ]]; then
        keys_dir="$default_path"
    else
        echo -n "Please specify the keys directory: "
        read keys_dir
    fi

    # Function to list keys in the directory
    list_keys() {
        echo "Available keys in $keys_dir:"
        ls "$keys_dir"
    }

    # Function to add keys manually
    add_keys_manually() {
        while true; do
            echo -n "Enter the SSH key to send: "
            read key
            selected_keys+=("$keys_dir/$key")
            echo -n "Is that all? (y/n): "
            read done
            [[ "$done" == "y" ]] && break
        done
    }

    # Function to add keys using grep filter
    add_keys_with_grep() {
        echo -n "Enter the grep pattern to filter keys: "
        read pattern
        local filtered_keys=($(ls "$keys_dir" | grep "$pattern"))
        echo "Filtered keys:"
        printf "%s\n" "${filtered_keys[@]}"
        echo -n "Is this list correct? (y/n): "
        read confirm
        if [[ "$confirm" == "y" ]]; then
            for key in "${filtered_keys[@]}"; do
                selected_keys+=("$keys_dir/$key")
            done
        fi
    }

    # Function to list selected keys
    list_selected_keys() {
        echo "Selected keys to send:"
        printf "%s\n" "${selected_keys[@]}"
    }

    # Function to remove selected keys using Vim
    remove_selected_keys() {
        local temp_file=$(mktemp)
        printf "%s\n" "${selected_keys[@]}" > "$temp_file"
        vim "$temp_file"
        selected_keys=($(cat "$temp_file"))
        rm "$temp_file"
    }

    # Main menu
    while true; do
        echo "Menu:"
        echo "1. Add SSH keys manually"
        echo "2. Add SSH keys using grep filter"
        echo "3. List selected keys"
        echo "4. Remove selected keys"
        echo "5. List keys in SSH directory"
        echo "6. Continue to target server(s) step"
        echo -n "Choose an option: "
        read choice

        case $choice in
            1) add_keys_manually ;;
            2) add_keys_with_grep ;;
            3) list_selected_keys ;;
            4) remove_selected_keys ;;
            5) list_keys ;;
            6) break ;;
            *) echo "Invalid option, please try again." ;;
        esac
    done

    # Target server(s) step
    while true; do
        echo "Selected keys to send:"
        printf "%s\n" "${selected_keys[@]}"
        echo -n "Enter the target server SSH address (user@domain.com): "
        read server
        server=$(echo "$server" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        echo -n "Do you need to specify an SSH key to use? (y/n): "
        read use_key
        if [[ "$use_key" == "y" ]]; then
            echo -n "Do you want to use the default path ($default_path)? (y/n): "
            read use_default_key
            if [[ "$use_default_key" == "y" ]]; then
                echo -n "Enter the key name: "
                read key_name
                target_servers+=("$server -i $default_path/$key_name")
            else
                echo -n "Enter the full path to the SSH key: "
                read key_path
                target_servers+=("$server -i $key_path")
            fi
        else
            target_servers+=("$server")
        fi
        echo -n "Do you want to add another server? (y/n): "
        read add_another
        [[ "$add_another" == "n" ]] && break
    done

    # Ask for SSH key passphrase if necessary
    echo -n "Enter SSH key passphrase (leave blank if not needed): "
    read -s ssh_passphrase
    echo

    # Deploy keys to target servers using scp
    for server in "${target_servers[@]}"; do
        for key in "${selected_keys[@]}"; do
            echo "Deploying $key to $server"
            if [[ -n "$ssh_passphrase" ]]; then
                if [[ "$server" == *"-i"* ]]; then
                    local ssh_key="${server#*-i }"
                    local ssh_server="${server%-i*}"
                    ssh_server=$(echo "$ssh_server" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                    local scp_command="$HOME/koby-dev-env/util/ssh/ssh_with_passphrase.exp \"$ssh_passphrase\" \"$ssh_key\" \"$key\" \"$ssh_server:~/.ssh/\""
                    echo "Running command: $scp_command"
                    eval $scp_command
                else
                    server=$(echo "$server" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                    local scp_command="$HOME/koby-dev-env/util/ssh/ssh_with_passphrase.exp \"$ssh_passphrase\" \"\" \"$key\" \"$server:~/.ssh/\""
                    echo "Running command: $scp_command"
                    eval $scp_command
                fi
            else
                if [[ "$server" == *"-i"* ]]; then
                    local ssh_key="${server#*-i }"
                    local ssh_server="${server%-i*}"
                    ssh_server=$(echo "$ssh_server" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                    local scp_command="scp -i \"$ssh_key\" \"$key\" \"$ssh_server:~/.ssh/\""
                    echo "Running command: $scp_command"
                    eval $scp_command
                else
                    server=$(echo "$server" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                    local scp_command="scp \"$key\" \"$server:~/.ssh/\""
                    echo "Running command: $scp_command"
                    eval $scp_command
                fi
            fi
        done
    done
}
