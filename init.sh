#!/bin/bash

# Export a variable to be used in the tasks.ini
export DEV_INIT_SESSION_ID=$(uuidgen | tr -d '-' | cut -c1-6)

# Backup function for any existing configs (used in tasks.ini)
export backup_file() {
  local original_file="$1"
  local backup_file="${original_file}.bk-${DEV_INIT_SESSION_ID}"

  if [ ! -f "$original_file" ]; then
    echo "Error: File $original_file does not exist."
    return 1
  fi

  mv "$original_file" "$backup_file"

  if [ $? -eq 0 ]; then
    echo "Backup created: $backup_file"
  else
    echo "Error: Failed to create backup of $original_file"
    return 2
  fi
}

# Link function to link configs to necessary location (used in tasks.ini)
export link_file() {
    local source_file="$1"
    local target_file="$2"

    # Check if source file exists
    if [ ! -e "$source_file" ]; then
        echo "Error: Source file $source_file does not exist."
        return 1
    fi

    # If target file already exists, back it up
    if [ -e "$target_file" ]; then
        backup_file "$target_file"
        rm "$target_file"
    fi

    # Create symbolic link
    ln -s "$source_file" "$target_file"

    if [ $? -eq 0 ]; then
        echo "Symbolic link created: $target_file -> $source_file"
    else
        echo "Error: Failed to create symbolic link from $source_file to $target_file"
        return 2
    fi
}

# Detect package manager
detect_package_manager() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew >/dev/null 2>&1; then
            export PACKAGE_MANAGER="brew"
        else
            echo "Homebrew not found. Please install Homebrew: https://brew.sh/"
            exit 1
        fi
    elif command -v apt-get >/dev/null 2>&1; then
        # Debian-based systems
        export PACKAGE_MANAGER="apt-get"
    elif command -v dnf >/dev/null 2>&1; then
        # Newer Red Hat-based systems
        export PACKAGE_MANAGER="dnf"
    elif command -v yum >/dev/null 2>&1; then
        # Older Red Hat-based systems
        export PACKAGE_MANAGER="yum"
    else
        echo "Unable to determine package manager. Supported systems: macOS, Debian-based, and Red Hat-based."
        exit 1
    fi

    echo "Detected package manager: $PACKAGE_MANAGER"
}

# Function to read tasks from file
read_tasks() {
    local task_file="$1"
    local task_name=""
    local tasks=()
    local commands=()

    while IFS= read -r line; do
        if [[ $line =~ ^\[.*\]$ ]]; then
            if [ ! -z "$task_name" ]; then
                tasks+=("$task_name")
                commands+=("${command_block}")
            fi
            task_name="${line:1:-1}"  # Remove brackets
            command_block=""
        elif [ ! -z "$line" ] && [[ ! $line =~ ^#.* ]]; then
            command_block+="$line"$'\n'
        fi
    done < "$task_file"

    # Add the last task
    if [ ! -z "$task_name" ]; then
        tasks+=("$task_name")
        commands+=("${command_block}")
    fi

    echo "${tasks[@]}"$'\n'"${commands[@]}"
}

# Function to display menu and get user selection
display_menu() {
    local options=("$@")
    local selected=()
    local current=0

    while true; do
        clear
        echo "Select tasks to execute (use arrow keys, space to select, enter to confirm):"
        for i in "${!options[@]}"; do
            if [[ " ${selected[*]} " =~ " ${i} " ]]; then
                echo "[X] ${options[i]}"
            else
                echo "[ ] ${options[i]}"
            fi
        done

        read -rsn1 key
        case "$key" in
            $'\x1B')  # Arrow keys
                read -rsn2 key
                case "$key" in
                    '[A') ((current > 0)) && ((current--)) ;;  # Up arrow
                    '[B') ((current < ${#options[@]}-1)) && ((current++)) ;;  # Down arrow
                esac
                ;;
            '') 
                if [[ " ${selected[*]} " =~ " ${current} " ]]; then
                    selected=(${selected[@]/$current})
                else
                    selected+=($current)
                fi
                ;;
            $'\x0A')  # Enter key
                break
                ;;
        esac
    done

    echo "${selected[@]}"
}

# Function to execute a task
execute_task() {
    local task="$1"
    local commands="$2"
    echo "Executing task: $task"
    eval "$commands"
}

# Main execution
IFS=$'\n' read -d '' -r -a task_data < <(read_tasks "tasks.ini")
tasks=("${task_data[@]:0:${#task_data[@]}/2}")
commands=("${task_data[@]:${#task_data[@]}/2}")
tasks=("Execute all tasks" "${tasks[@]}")

echo "Welcome to the Linux environment setup script!"
echo "Please select the tasks you want to execute:"

selected_indices=($(display_menu "${tasks[@]}"))

# Execute selected tasks
for index in "${selected_indices[@]}"; do
    if [ "$index" -eq 0 ]; then
        # Execute all tasks
        for i in "${!tasks[@]}"; do
            if [ "$i" -ne 0 ]; then
                execute_task "${tasks[i]}" "${commands[i-1]}"
            fi
        done
    else
        execute_task "${tasks[index]}" "${commands[index-1]}"
    fi
done

echo "Setup complete!"
