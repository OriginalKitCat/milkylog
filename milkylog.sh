#Milkylog by KitCat. Made with <§

#!/bin/bash

# ------ Librarys needed ------
# moreutils
# touch
# echo
# mkdir
# read
# jq
# getopts
# -----------------------------

user_data_file="$HOME/.milkyway/users.json"
milkyway_dir="$HOME/.milkyway"
# website="http://localhost:5173" #For local Tests
website="https://milkyway.hackclub.com" #THE milkyway milyway website
show_help=false
show_version=false
setup=false
folderattach=false
noneinput=false
username_is_valid=false
create_devlog=false
debug=false

version="0.5.2"
#This is only for my local setup valid, not the milkyway milkyway, make yourself no hopes...
SESSIONID="" #Cookie from the website, have to ask later on for it in setup
SESSIONID=$( jq -r '.sessionid' $user_data_file)
STORAGE="[]"

activate_debug() { #I know it's a very very short function...
    debug=true
    print_ses_id
}

print_ses_id() {
    echo "Your current session Id: $SESSIONID"
}

checkUserName() {
    LOCAL_USERNAME="$1"

    # Send POST request to check username
    RESPONSE=$(curl -s -X POST $website/api/check-username \
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
    
    RESPONSE=$(curl -s -X POST $website/api/user-mail-match \
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
    echo "$RESPONSE"
}

send_devlog() {
    LOCAL_EMAIL="$1"
    GIVEN_USERNAME="$2"
    TITLE="$3"
    description="$4"
    selected_projects="$5"
    attached_image_path="$6"

    RESPONSE=$(curl -s -X POST $website/api/create-devlog \
        -H "Cookie: sessionid=$SESSIONID" \
        -F "title=$TITLE" \
        -F "description=$description" \
        -F "selectedProjects=$selected_projects" \
        -F "photo0=@$attached_image_path")
        # -F "photo1=@$attached_image_path")

    SUCCESS=$(echo "$RESPONSE" | jq -r '.success')
    streak=$(echo "$RESPONSE" | jq -r '.streak.streak')

    if [ "$SUCCESS" == "true" ]; then
        echo "successful."
        echo "Your streak: $streak"
        if [ "$debug" == "true" ]; then
            echo "projectIds for sending: $projectIds"
        fi
    else
        ERROR=$(echo "$RESPONSE" | jq -r '.error.message')
        echo "API Response for devlog: $RESPONSE"
        echo "Error: $ERROR"
        if [ -z "$ERROR" ]; then
            echo "The backend is not giving a response. Pls remind me via Slack to fix this (@KitCat)"
        fi
        echo "Why so grumpy? It's nothing more than an error."
        exit 1
    fi

    if [ "$debug" == "true" ]; then
        echo "API Response for devlog: $RESPONSE"
    fi
}

show_version() {
    echo "Milkylog version $version"
}

show_help() {
    echo "Milkylog by KitCat"
    echo
    echo "Usage: Milkylog [-h] [-v] [-s] [-f] [...]"
    echo
    echo "Options:"
    echo "  -b    Activate debugging"
    echo "  -h    Display this help message."
    echo "  -s    Setup Script (You have to run this before you can make Devlogs.)"
    echo "  -f    Outdated: Attach current folder to an existing Project"
    echo "  -v    Display the version."
    echo "  -i    Get your saved session Id-"
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
    read -p "Enter the session id from milkyway here: " api_key
    SESSIONID="$api_key"
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
    nameExistCheck=$(jq -r 'has("username")' $user_data_file)
    emailExistCheck=$(jq -r 'has("email")' $user_data_file)
    sesIdExistCheck=$(jq -r 'has("sessionid")' $user_data_file)
    jq 'select(.username? == null and .email? == null and .sessionid? == null)' users.json | sponge $user_data_file
    jq -n --arg user "$username" --arg email "$user_email" --arg sessionid "$SESSIONID" '{username: $user, email: $email, sessionid: $sessionid}' >> "$user_data_file"
    echo "Done."
}

getProjectHoursToday() {
    url="$website/api/get-projects-hours-today"
    echo "Fetching project code- and arthours"
    RESPONSE=$(curl -X POST "$url" -H "Content-Type: application/json" -H "Cookie: sessionid=$SESSIONID" -d '{}')
    if [ $? -ne 0 ]; then
        echo "Failed to connect to the server."
        exit 1
    fi
    # totaltime=$(jq -r '.projects[].totalHours')
    # projectname=$(jq -r '.projects[].name')
    # codehours=$(jq -r '.projects[].codeHours')
    # projectarthours=$(jq -r '.projects[].artHours')

    PROJECTS_COUNT=$(echo "$RESPONSE" | jq '.projects | length')
    if [ "$PROJECTS_COUNT" -eq 0 ]; then
        echo "Error: There were probably no hours coded / logged today."
        exit 1
    else
        echo "Projects:"
        echo "$RESPONSE" | jq -r '.projects[] | "Name: \(.name), Id: \(.id), Total hours: \(.totalHours), Hackatime hours: \(.codeHours), Art hours: \(.artHours)"'
        echo ""
    fi
    # echo "$projectname Total hours: $totaltime (Hackatime hours: $codehours Art hours: $projectarthours)"
    if [ "$debug" == "true" ]; then
        echo "Serverside response: $RESPONSE"
    fi
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
    read -p "Attach an project with at least 1h logged today to the dev log by COPYING THE PROJECTS' IS(s) : " devl_project_id
    echo "sending devlog ..."
    send_devlog KitCat originalkitcat@proton.me $devl_title $devl_discription $devl_project_id $devl_image_path
    echo "Devlog send. You're save from mimi today ... probatly"
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

while getopts "bhvdsi:" option; do
    case $option in
        b)  activate_debug ;;
        h)  show_help ;;
        v)  show_version ;;
        d)  create_devlog ;;
        s)  setup_script ;;
        i)  print_ses_id ;;
        \?) show_help ;;
    esac
done


echo "Script Finished succesfully."
