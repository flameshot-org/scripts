#!/bin/env bash

################################################################################
## Title: Upload your screenshots to a server via sftp                        ##        
################################################################################
## Description:                                                               ##
## ??????????                                                                 ##
################################################################################
## Maintainer:                                                                ##
##  - Matthias                                                                ##
##    - Github: @mxtthiasss                                                   ##
##    - Matrix: @mxtthiass:matrix.org                                         ##
##    - email : mxtthiass@yasuakii.com                                        ##
## Contributors:                                                              ##
##  -                                                                         ##
# ###############################################################################
## License:                                                                   ##
## GPLv3+                                                                     ##
################################################################################

PORT=22 # Port of the server default one is 22
USER="root" # Username you login in on the server
SFTPSERVER="1.1.1.1" # ip from your server or domain
STORAGE="~/Pictures/Screenshots" # Path where the screenshots are stored
PATHONSERVER="~/cdn/src" # Path where the screenshots where stored on the server
LINK="example.com" # Link to you want to acces the screenshot from
SSHKEY="~/.ssh/" # path from you ssh key if you want to use one


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
PATHONSERVER="$(eval echo "${PATHONSERVER}")"
SSHKEY="$(eval echo "${SSHKEY}")"

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

scp -i "${SSHKEY}" \
    -P "${PORT}" \
    -o PasswordAuthentication=no \
    -o PubkeyAcceptedKeyTypes=+ssh-rsa \
    "${STORAGE}/${FILE}" \
    "${USER}@${SFTPSERVER}:${PATHONSERVER}" \

# copy the link to the clipboard
 if [ $? -ne 0 ]; then
  notify-send --icon terminal --category 'transfer.error' "Screenshot upload error" "Could not upload $FILE to $SFTPSERVER"
else
  URL="$LINK/$FILE"
  echo $URL | xclip -selection clipboard
fi

