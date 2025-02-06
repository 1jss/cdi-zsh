#!/bin/zsh
#
# CDI - Change Dir Interactively
# Don't waste more time in the terminal browsing folders with CD

# Change field separator to new-line to easily handle spaces in folder names.
IFS=$'\n'

print_folders() {
    # $1 = current_dir
    # $2 = current_selection

    # List files and filter only those ending with "/"
    array=()
    while IFS= read -r folder; do
        # Only add non-empty folder names
        if [[ -n "$folder" ]]; then
            array+=("$folder")
        fi
    done < <(ls -p $1 | grep /)

    folders_list_size=$(( ${#array[@]} ))

    if [[ ${#array[@]} -ne 0 ]]; then
        # Iterate through the array with zero-based indexing
        for index in {1..$folders_list_size}; do
            if [[ "$index" -eq "$2" ]]; then
                echo -e "\033[1m→ ${array[$index]}\033[0m"
            else
                echo "  ${array[$index]}"
            fi
        done
    else
        echo -e 'No folders here, press \033[1m←\033[0m to back'
    fi
}

print_status() {
    echo -e "[ \033[1m$1\033[0m ]\n"
}

get_selected_folder() {
    # $1 = current_dir
    # $2 = current_selection

    array=()
    while IFS= read -r folder; do
        # Only add non-empty folder names
        if [[ -n "$folder" ]]; then
            array+=("$folder")
        fi
    done < <(ls -p $1 | grep /)

    selected_folder="${array[$2]}"  # Get the folder name based on selection
    selected_folder="${selected_folder%/}"  # Remove trailing slash
}

init() {
    # Initial values
    current_dir=$(pwd)
    current_selection=1

    # Save terminal settings and switch to raw mode
    old_stty=$(stty -g)
    stty -icanon -echo  # Disable canonical mode (for instant key reading)

    # Main loop
    while true; do
        clear  # Clear the screen once at the start of each loop
        print_status "$current_dir"
        print_folders "$current_dir" "$current_selection"

        # Read the keypress (1 byte at a time)
        key=$(dd bs=1 count=1 2>/dev/null)

        # Check for arrow keys and handle them
        case "$key" in
            $'\e')  # Start of an escape sequence
                key2=$(dd bs=1 count=1 2>/dev/null)
                key3=$(dd bs=1 count=1 2>/dev/null)
                if [[ "$key2" == "[" ]]; then
                    case "$key3" in
                        A)  # UP arrow
                            if [[ "$current_selection" -eq 1 ]]; then
                                current_selection=$folders_list_size
                            else
                                current_selection=$((current_selection - 1))
                            fi
                            ;;
                        B)  # DOWN arrow
                            if [[ "$current_selection" -eq "$folders_list_size" ]]; then
                                current_selection=1
                            else
                                current_selection=$((current_selection + 1))
                            fi
                            ;;
                        D)  # LEFT arrow
                            current_dir=${current_dir%/*}
                            current_selection=1
                            ;;
                        C)  # RIGHT arrow
                            get_selected_folder "$current_dir" "$current_selection"
                            current_dir="$current_dir/$selected_folder"
                            current_selection=1
                            ;;
                    esac
                fi
                ;;
            "")  # Enter key (exit)
                stty "$old_stty"  # Restore terminal settings
                if [[ -d "$current_dir" ]]; then
                    cd "$current_dir"  # Change directory in the current shell
                    return  # Exit the loop after changing directory
                else
                    echo "Directory '$current_dir' does not exist."
                    exit 1
                fi
                ;;
        esac
    done
}

init
