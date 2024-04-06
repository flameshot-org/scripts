#!/bin/bash

API_KEY="" # vgy.me api
STORAGE="" # Path where the screenshots are stored


# grab the file format that is defined by the user in the Flameshot config
SCREENSHOT_FORMAT="$(grep -P -o '(?<=^saveAsFileExtension\=).+$' ~/.config/flameshot/flameshot.ini)"
# if no format was specified
if [ "${SCREENSHOT_FORMAT}" == "" ]; then
    # fallback to png which is default of Flameshot
    SCREENSHOT_FORMAT="png"
fi

# construct the file name
FILE="$(date +%F_%H.%M.%S)_$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 10).${SCREENSHOT_FORMAT}"

# a little trick to expand tilde (~) to the actual path
STORAGE="$(eval echo "${STORAGE}")"
# make sure the local folder exists
mkdir --parents "${STORAGE}"

# take the screenshot and capture the output
FLAMESHOT_STATUS=$(flameshot gui --path "${STORAGE}/${FILE}" 2>&1)

# check if user aborted the screenshot
if [ "${FLAMESHOT_STATUS}" == "flameshot: info: Screenshot aborted." ]; then
    echo "The screenshot process was aborted"
    exit 0
fi

# inform the user
echo "${STORAGE}/${FILE} created!"

# Sending file
response=$(curl -X POST -F "file=@${STORAGE}/${FILE}" -F "userkey=$API_KEY" https://vgy.me/upload)


# Checking response
if [ $? -eq 0 ]; then
    error=$(echo "$response" | jq -r '.error')
    if [ "$error" == "true" ]; then
        messages=$(echo "$response" | jq -r '.messages')
        echo "Error: $messages" | tee -a output.log
        notify-send --icon terminal --category 'transfer.error' "Screenshot upload error" "$messages"
    else
        image_url=$(echo "$response" | jq -r '.image')
        echo "$image_url" | tee -a output.log | xclip -selection clipboard
        notify-send --icon terminal --category 'transfer.success' "Screenshot uploaded successfully" "Screenshot link copied to clipboard"
    fi
else
    echo "Error: Request failed" | tee -a output.log
    notify-send --icon terminal --category 'transfer.error' "Screenshot upload error" "Request Failed"
    exit 1
fi
