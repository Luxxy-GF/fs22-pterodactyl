#!/bin/bash

# Set working directory
cd /home/container

# Display system information
echo "Running on Debian version: $(cat /etc/debian_version)"
echo "Current timezone: $(cat /etc/timezone)"
echo "Wine version: $(wine --version)"
export DISPLAY=":1"


# Make internal Docker IP address available to processes
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Define Wine prefix path
export WINEPREFIX=/home/container/.wine
export WINEDEBUG=-all

# Ensure Wine prefix directory exists
echo "Creating Wine prefix directory..."
mkdir -p "$WINEPREFIX"

# Set new VNC password if available
if [ -f /home/container/.vnc/passwd ]; then
    echo "Setting VNC password..."
    echo -e "${VNC_PASS}\n${VNC_PASS}\n" | vncpasswd -u admin -w -r
    cat "dead" > /home/container/.vnc/passwd
fi

# Check if wine-mono required and install it if so
if [[ $WINETRICKS_RUN =~ mono ]]; then
        echo "Installing mono"
        WINETRICKS_RUN=${WINETRICKS_RUN/mono}

        if [ ! -f "$WINEPREFIX/mono.msi" ]; then
                wget -q -O $WINEPREFIX/mono.msi https://dl.winehq.org/wine/wine-mono/9.3.0/wine-mono-9.3.0-x86.msi
        fi

        wine msiexec /i $WINEPREFIX/mono.msi /qn /quiet /norestart /log $WINEPREFIX/mono_install.log
fi

# Install additional Winetricks
for trick in $WINETRICKS_RUN; do
    echo "Installing Winetrick: $trick"
    winetricks -q "$trick"
done

# Kill any old VNC sessions if running
echo "Killing any existing VNC sessions..."
[ -z "${DISPLAY}" ] || /usr/bin/vncserver -kill "${DISPLAY}"

# Clean up potential leftover lock files
echo "Removing leftover VNC lock files..."
find /tmp -maxdepth 1 -name ".X*-lock" -type f -exec rm -f {} \;
if [[ -d /tmp/.X11-unix ]]; then
    find /tmp/.X11-unix -maxdepth 1 -name 'X*' -type s -exec rm -f {} \;
fi

# Check if FS_VERSION is not 22 or 25
if [[ "${FS_VERSION}" != "22" && "${FS_VERSION}" != "25" ]]; then
  # Set FS_VERSION to 22
  FS_VERSION="22"
  echo "FS_VERSION is set to 22"
else
  echo "FS_VERSION is to Farming Simulator 20${FS_VERSION}"
fi

# Handle various progression states
if [ "${PROGRESSION}" == "INSTALL_SERVER" ]; then
    /usr/bin/vncserver -xstartup /home/container/.vnc/xstartup -geometry 1920x1080 -rfbport "${VNC_PORT}" -desktop x11
     # Check if the directory is writable and the file exists
    if [ "1" == "1" ]; then
        echo "You have write permission to the /fs directory and the file the server files seems to exists."
        STARTCMD="wine /fs/FarmingSimulator20${FS_VERSION}.exe"
    else
        echo "Either you do not have write permission to the /fs directory, or the server files not exist."
        exit 1
        STARTCMD="sleep 50"
    fi
elif [ "${PROGRESSION}" == "INSTALL_DLC" ] && [ ! -z "${DLC_EXE}" ]; then
    /usr/bin/vncserver -xstartup /home/container/.vnc/xstartup -geometry 1920x1080 -rfbport "${VNC_PORT}" -desktop x11
    STARTCMD="wine /home/container/dlc_install/${DLC_EXE}"
elif [ "${PROGRESSION}" == "SETUP_VNC" ]; then
    # Set up VNC configuration if it doesn't already exist
    echo "Setting up VNC configuration..."
    if [ -f "/home/container/.vnc/passwd" ]; then
        echo "VNC configuration already exists."
    else
        mkdir -p /home/container/.vnc && cd /home/container/.vnc
        wget https://raw.githubusercontent.com/QuintenQVD0/yolks/refs/heads/master/temp/experimental/xstartup
        touch /home/container/.vnc/passwd /home/container/.Xauthority
        chmod 600 /home/container/.vnc/passwd
        chmod 755 /home/container/.vnc/xstartup
    fi
    echo "Please stop the server and set the PROGRESSION variable to INSTALL_SERVER"
    STARTCMD="sleep 20"

elif [ "${PROGRESSION}" == "ACTIVATE" ] && [ -f "/home/container/.vnc/passwd" ]; then
    # Activate VNC and set the start command for the game
    echo "Activating VNC server..."
    /usr/bin/vncserver -xstartup /home/container/.vnc/xstartup -geometry 1920x1080 -rfbport "${VNC_PORT}" -desktop x11
    STARTCMD="wine /home/container/Farming\ Simulator\ 20${FS_VERSION}/FarmingSimulator20${FS_VERSION}.exe"

elif [ "${PROGRESSION}" == "RUN" ] && [ -f "/home/container/.vnc/passwd" ]; then
    # Prepare the startup command using environment variables
    echo "Preparing startup command..."
    /usr/bin/vncserver -xstartup /home/container/.vnc/xstartup -geometry 1920x1080 -rfbport "${VNC_PORT}" -desktop x11
    STARTCMD=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')

elif [ "${PROGRESSION}" == "UPDATE" ]; then
        # Update the server
        echo "Updating the server..."
        /usr/bin/vncserver -xstartup /home/container/.vnc/xstartup -geometry 1920x1080 -rfbport "${VNC_PORT}" -desktop x11
        STARTCMD="wine /home/container/Farming\ Simulator\ 20${FS_VERSION}/FarmingSimulator20${FS_VERSION}.exe"

        echo -e "Please stop the server and set the PROGRESSION variable to RUN"
        sleep 20

else
    # Unrecognized progression state
    echo "Error: The PROGRESSION variable is set to an unknown value."
    exit 1

    STARTCMD="sleep 50"
fi

rm -rf /home/container/.nginx/tmp/*
echo "⟳ Starting Nginx..."
nginx -c /home/container/.nginx/nginx/nginx.conf -p /home/container/.nginx/
echo "✓ started Nginx..."


# Echo the final startup command
echo "Starting with command: ${STARTCMD}"

# Execute the startup command
eval "${STARTCMD}"