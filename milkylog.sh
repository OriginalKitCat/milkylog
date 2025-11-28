#!/bin/bash

user_data_file="$HOME/.milkyway/users.json"
milkyway_dir="$HOME/.milkyway"

show_help=false
show_version=false
setup=false
folderattach=false
noneinput=false
username_is_valid=false
create_devlog=false

version="0.4.3"
#This is only for my local setup valid, not the milkyway milkyway, make yourself no hopes...
SESSIONID="c9b0d535-2d3b-401c-9636-5ca6b0fff829" #Cookie from the website, have to ask later on for it in setup

checkUserName() {
    LOCAL_USERNAME="$1"

    # Send POST request to check username
    RESPONSE=$(curl -s -X POST http://localhost:5173/api/check-username \
        -H "Content-Type: application/json" \
        -H "Cookie: sessionid=$SESSIONID" \
        -d "{\"username\": \"$LOCAL_USERNAME\"}")

    # Parse the response
    SUCCESS=$(echo "$RESPONSE" | jq -r '.success')
    AVAILABLE=$(echo "$RESPONSE" | jq -r '.available')
    ISINDATABASE=$( [ "$AVAILABLE" = true ] && echo false || echo true )

    if [ "$SUCCESS" == "true" ]; then
        echo "Username '$LOCAL_USERNAME' is in the database: $ISINDATABASE"
    else
        ERROR=$(echo "$RESPONSE" | jq -r '.error.message')
        echo "Error: $ERROR"
        exit 0;
    fi

    if [ "$AVAILABLE" != true ]; then
        username_is_valid=true
    else
        username_is_valid=false
    fi
}

checkEmailNameMatch() {
    LOCAL_EMAIL="$1"
    GIVEN_USERNAME="$2"
    
    RESPONSE=$(curl -s -X POST http://localhost:5173/api/user-mail-match \
        -H "Content-Type: application/json" \
        -H "Cookie: sessionid=$SESSIONID" \
        -d "{\"mail\": \"$LOCAL_EMAIL\", \"givenusername\": \"$GIVEN_USERNAME\"}")

    SUCCESS=$(echo "$RESPONSE" | jq -r '.success')

    if [ "$SUCCESS" == "true" ]; then
        echo "Check for username '$GIVEN_USERNAME' with email '$LOCAL_EMAIL' was successful."
    else
        ERROR=$(echo "$RESPONSE" | jq -r '.error.message')
        echo "Error: $ERROR"
        echo "Make sure your email adress matches your username."
        exit 0
    fi
    #For debug purposes only: echo "API Response for email check: $RESPONSE"
}

send_devlog() {
    LOCAL_EMAIL="$1"
    GIVEN_USERNAME="$2"
    TITLE="$3"
    description="$4"
    selected_projects="$5"
    attached_image_path="$6"

    RESPONSE=$(curl -s -X POST http://localhost:5173/api/create-devlog \
        -H "Cookie: sessionid=$SESSIONID" \
        -F "title=$TITLE" \
        -F "description=$description" \
        -F "selectedProjects=8" \
        -F "photo0=$attached_image_path")
        # -F "photo1=@$attached_image_path")


    SUCCESS=$(echo "$RESPONSE" | jq -r '.success')
    echo "API Response for devlog: $RESPONSE"
    
    if [ "$SUCCESS" == "true" ]; then
        echo "successful."
    else
        ERROR=$(echo "$RESPONSE" | jq -r '.error.message')
        echo "API Response for devlog: $RESPONSE"
        echo "Error: $ERROR"
        echo "Why so grumpy? It's nothing more than an error."
        exit 1
    fi
    
    echo "API Response for devlog: $RESPONSE"
}

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
    echo "Checking the database for username..."
    checkUserName "$username"
    if [ "$username_is_valid" == false ]; then
        echo "The provided username '$username' was not found in the database. Please enter a valid name."
        exit 1
    fi
    echo "Username check successful!"
    echo "Success!"
    read -p "Enter the email connected to your account: " user_email
    if [[ "$user_email" != *"@"* ]] || [[ "$user_email" != *"."* ]]; then
        echo "The provided email is invalid. Please make sure it contains '@' and '.' ."
        exit 1
    fi
    echo "Checking the database..."
    checkEmailNameMatch  $user_email $username
    #I have to insert a database check here too.
    usern_check=true 
    if [ "$usern_check" == false ]; then
        echo "The provided email was not in the database or did't matched the user $username. Please enter a valid e-mail."
        exit 1
    fi
    echo "Success!"
    echo "Setting up Milkylog for user '$username' with email '$user_email'..."
    echo "Saving recived user data..."
    jq -n --arg user "$username" --arg email "$user_email" '{username: $user, email: $email}' >> "$user_data_file"
    echo "Done."
}

getProjectHoursToday() {
    url="http://localhost:5173/api/get-projects-hours-today"
    response=$(curl -X POST "$url" -H "Content-Type: application/json" -H "Cookie: sessionid=$SESSIONID" -d '{}')
    projectname=$(echo "$RESPONSE" | jq -r '.name')
    echo "Respones: $projectname"
}

create_devlog() {
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
    # here i have to insert a function that reas cookie, username and email from the data
    username="KitCat"
    user_email="originalkitcat@proton.me"
    SESSIONID="c9b0d535-2d3b-401c-9636-5ca6b0fff829"
    read -p "Enter your devlog's title: " devl_title
    read -p "Enter your devlog's description: " devl_discription
    read -p "Attach an image or an video (Smaller than 10 MB): " devl_image_path
    if [ ! -f "$devl_image_path" ]; then
        echo "This file couldn't be found. Please make sure the file exists."
        exit 1
    elif [[ ! "$devl_image_path" == *.png && ! "$devl_image_path" == *.jpeg && ! "$devl_image_path" == *.gif && ! "$devl_image_path" == *.mp4 && ! "$devl_image_path" == *.mov && ! "$devl_image_path" == *.jpg ]]; then
        echo "Incompatible file format. Use png, jpeg, gif, mp4, mov or webm."
        exit 1
    else
        echo "File exists and is compartible."
    fi
    getProjectHoursToday
    read -p "Attach an project with at least 1h logged today to the dev log by copying the name here: " devl_project_name
    echo "sending devlog ..."
    send_devlog KitCat originalkitcat@proton.me $devl_title $devl_discription $devl_project_name $devl_image_path
    echo "Devlog send. You're save from mimi today ... probatly"
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

while getopts "hvds:" option; do
    case $option in
        h)  show_help ;;
        v)  show_version ;;
        d)  create_devlog ;;
        s)  setup_script ;;
        # d)  create_devlog ;;
        \?) show_help ;;
    esac
done


echo "Script Finished"
