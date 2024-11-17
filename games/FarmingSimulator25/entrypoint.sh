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
    echo "${VNC_PASS}" | vncpasswd -f > /home/container/.vnc/passwd
    echo "${VNC_PASS}" | vncpasswd > /home/container/.vnc/passwd
fi

# Kill any old VNC sessions if running
echo "Killing any existing VNC sessions..."
[ -z "${DISPLAY}" ] || /usr/bin/vncserver -kill "${DISPLAY}"

# Clean up potential leftover lock files
echo "Removing leftover VNC lock files..."
find /tmp -maxdepth 1 -name ".X*-lock" -type f -exec rm -f {} \;
if [[ -d /tmp/.X11-unix ]]; then
    find /tmp/.X11-unix -maxdepth 1 -name 'X*' -type s -exec rm -f {} \;
fi

# Start KasmVNC server
echo "Starting KasmVNC server..."
# Automatically choose option [2] to start KasmVNC without a user with write access
echo "2" | /usr/bin/kasmvncserver --geometry 1920x1080 --port ${VNC_PORT} --password ${VNC_PASS}
# Ensure the script exists and has proper permissions
chmod +x /usr/lib/kasmvncserver/select-de.sh
KASMVNC_PID=$!

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
    if [ "1" == "1" ]; then
        echo "You have write permission to the /fs directory and the server files seem to exist."
        STARTCMD="wine /fs/FarmingSimulator20${FS_VERSION}.exe"
    else
        echo "Either you do not have write permission to the /fs directory, or the server files do not exist."
        exit 1
        STARTCMD="sleep 50"
    fi
elif [ "${PROGRESSION}" == "INSTALL_DLC" ] && [ ! -z "${DLC_EXE}" ]; then
    STARTCMD="wine /home/container/dlc_install/${DLC_EXE}"
elif [ "${PROGRESSION}" == "ACTIVATE" ] && [ -f "/home/container/.vnc/passwd" ]; then
    echo "Activating VNC server..."
    STARTCMD="wine /home/container/Farming\ Simulator\ 20${FS_VERSION}/FarmingSimulator20${FS_VERSION}.exe"
elif [ "${PROGRESSION}" == "RUN" ] && [ -f "/home/container/.vnc/passwd" ]; then
    echo "Preparing startup command..."
    STARTCMD=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
elif [ "${PROGRESSION}" == "UPDATE" ]; then
    echo "Updating the server..."
    STARTCMD="wine /home/container/Farming\ Simulator\ 20${FS_VERSION}/FarmingSimulator20${FS_VERSION}.exe"
    echo -e "Please stop the server and set the PROGRESSION variable to RUN"
    sleep 20
else
    echo "Error: The PROGRESSION variable is set to an unknown value."
    exit 1
    STARTCMD="sleep 50"
fi

# Remove temporary files
rm -rf /home/container/.nginx/tmp/*

# Start Nginx
echo "⟳ Starting Nginx..."
nginx -c /home/container/.nginx/nginx/nginx.conf -p /home/container/.nginx/
echo "✓ started Nginx..."

# Echo the display and startup command
echo "Display: ${DISPLAY}"
echo "Starting with command: ${STARTCMD}"

# Wait for KasmVNC to stabilize
sleep 5

# Execute the startup command
eval "${STARTCMD}"

# Ensure KasmVNC is cleaned up on exit
trap "kill ${KASMVNC_PID}" EXIT
