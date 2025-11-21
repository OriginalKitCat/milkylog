#!/bin/bash

user_data_file="$HOME/.milkyway/users.json"
milkyway_dir="$HOME/.milkyway"

show_help=false
show_version=false
setup=false
folderattach=false
noneinput=false

version="0.2.7"


show_version() {
    echo "Milkylog version $version"
}

showtime() {
    current_time=$(date +%r)
    echo $current_time
}

show_help() {
    echo "Milkylog by KitCat"
    echo
    echo "Usage: Milkylog [-h] [-v] [-s] [-f] [...]"
    echo
    echo "Options:"
    echo "  -h    Display this help message."
    echo "  -s    Setup Script (You have to run this before you can make Devlogs.)"
    echo "        Usage: -s [Milkyway user name] [e-mail]"
    echo "  -f    Attach current folder to an existing Project"
    echo "        Usage: -f [Project name]"
    echo "  -v    Display the version."
}

setup_script() {
    echo "Welcome to the Milkylog setup."
    echo "HOME is set to: $HOME"
    echo "Checking if $milkyway_dir exists..."
    if [ ! -d "$milkyway_dir" ]; then
        echo "Creating directory $milkyway_dir..."
        echo "Creating directory $milkyway_dir..."
        mkdir -p "$milkyway_dir" && echo "Directory created successfully." || echo "Failed to create directory."
    fi
    echo "checking if user data file exists..."
    if [ ! -f "$user_data_file" ]; then
        echo "Creating $user_data_file..."
        touch "$HOME/.milkyway/users.json"
    fi
    if [ ! -f "$user_data_file" ]; then
        echo "Error: $user_data_file could not be created."
        exit 1
    fi
    read -p "Enter your Milkyway user name (Has to exist in the database): " username
    echo "Checking the database..."
    #I have to insert a database check here.
    usern_check=true 
    if [ "$usern_check" == false ]; then
        echo "The provided name was not in the database. Please enter a valid name."
        exit 0
    fi
    echo "Success!"
    read -p "Enter the email connected to your account: " user_email
    if [[ "$user_email" != *"@"* ]] || [[ "$user_email" != *"."* ]]; then
        echo "The provided email is invalid. Please make sure it contains '@' and '.' ."
        exit 0
    fi
    echo "Checking the database..."
    #I have to insert a database check here too.
    usern_check=true 
    if [ "$usern_check" == false ]; then
        echo "The provided email was not in the database or did't matched the user $username. Please enter a valid e-mail."
        exit 0
    fi
    echo "Success!"
    echo "Setting up Milkylog for user '$username' with email '$user_email'..."
    echo "Saving recived user data..."
    jq -n --arg user "$username" --arg email "$user_email" '{username: $user, email: $email}' >> "$user_data_file"
    echo "Done."
}

get_existing_projects() {
    echo "You have created this Projects already:"
    #Here I'll have to make a list of a users Projects when the backend is finished...
}

attach_folder() {
    if [ ! -f "$user_data_file" ]; then
        echo "Setup is not done yet... Please do now or run milkylog -s"
        read -p "Do you want to setup now? (y/n): " choice
        choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
        if [[ "$choice" == "y" || "$choice" == "yes" ]]; then
            setup_script
        elif [[ "$choice" == "n" || "$choice" == "no" ]]; then
            echo "You can't continue without, please run this later: milkyway -s"
            exit 0
        else
            echo "Invalid input. Please answer with 'y' or 'n'."
            exit 0
        fi
    fi
    echo "Attaching current folder to project '$1'..."
}

if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

while getopts "hvfs:" option; do
    case $option in
        h)  show_help ;;
        v)  show_version ;;
        f)  attach_folder ;;
        s)  setup_script ;;
        \?)  show_help ;;
    esac
done


echo "Script Finished"
