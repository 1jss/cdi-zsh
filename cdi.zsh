#!/bin/zsh
#
# CDI - Change Dir Interactive

# Set Internal Field Separator (IFS) to newline (\n) to handle folder names that contain spaces.
IFS=$'\n'

# Function to display folder contents
# Takes two arguments:
#   $1: The currently viewed directory
#   $2: The index of the currently selected folder
print_folders() {
    # $1 = current_dir
    # $2 = current_selection

    # Get content of current_dir and store folders (ending with /) to an array
    # This also takes care of folders with spaces in their names
    array=()
    while IFS= read -r folder; do
        # Only add non-empty folder names
        if [[ -n "$folder" ]]; then
            array+=("$folder")
        fi
    done < <(ls -p $1 | grep /)

    # Get the number of items in the folder array.
    folders_list_size=$(( ${#array[@]} ))

    # Only draw folders if there are any
    if [[ ${#array[@]} -ne 0 ]]; then
        start_index=1
        end_index=$folders_list_size
        # Draw a maximum of 25 folders
        if [[ $folders_list_size -gt 25 ]]; then
            # Show 12 items before current_selection
            if [[ $2 -gt 12 ]]; then
                start_index=$(($2 - 12))
            fi

            # Show 12 items after current selection
            end_index=$((start_index + 24))
            if [[ $end_index -gt $folders_list_size ]]; then
                end_index=$folders_list_size
            fi
        fi

        # Ellipsis if truncated at top
        if [[ "$start_index" -ne 1 ]]; then
            echo "  ..."
        fi
        
        # Iterate through the array
        for index in {$start_index..$end_index}; do
            if [[ "$index" -eq "$2" ]]; then
                # Bold text and arrow on selected index
                echo -e "\033[1m→ ${array[$index]}\033[0m"
            else
                echo "  ${array[$index]}"
            fi
        done
        
        # Ellipsis if truncated at bottom
        if [[ "$end_index" -ne "$folders_list_size" ]]; then
            echo "  ..."
        fi
    else
        # No folders in current_dir
        echo -e 'No folders here, press \033[1m←\033[0m to go back or enter to select'
    fi
}

# Print curreent directory in bold
# Takes one argument:
#   $1: The currently viewed directory
print_status() {
    echo -e "[ \033[1m$1\033[0m ]\n"
}

# Get the name of currently selected folder
# Takes two arguments:
#   $1: The currently viewed directory
#   $2: The index of the currently selected folder
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
                                # Loop at the top
                                current_selection=$folders_list_size
                            else
                                current_selection=$((current_selection - 1))
                            fi
                            ;;
                        B)  # DOWN arrow
                            if [[ "$current_selection" -eq "$folders_list_size" ]]; then
                                # Loop at the bottom
                                current_selection=1
                            else
                                current_selection=$((current_selection + 1))
                            fi
                            ;;
                        D)  # LEFT arrow
                            current_dir=${current_dir%/*}
                            # Handle root folder
                            if [[ $current_dir == "" ]]; then
                                current_dir="/"
                            fi
                            current_selection=1
                            ;;
                        C)  # RIGHT arrow (only change if there are subfolders)
                            if [[ "$folders_list_size" -gt 0 ]]; then
                                get_selected_folder "$current_dir" "$current_selection"
                                # Prevent double slashes on root folder
                                if [[ $current_dir == "/" ]]; then
                                    current_dir=""
                                fi
                                current_dir="$current_dir/$selected_folder"
                                current_selection=1
                            fi
                            ;;
                    esac
                fi
                ;;
            "")  # Enter key (navigate and exit)
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
