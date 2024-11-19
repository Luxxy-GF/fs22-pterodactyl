# Base image
FROM debian:bookworm-slim

# Set environment to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Create a user for the container
RUN useradd -m -d /home/container -s /bin/bash container

# Install required packages
RUN dpkg --add-architecture i386 \
    && apt update -y \
    && apt install -y --no-install-recommends gnupg2 iproute2 wget numactl tzdata software-properties-common libntlm0 winbind xvfb xauth python3 libncurses5:i386 libncurses6:i386 libsdl2-2.0-0 libsdl2-2.0-0:i386 tightvncserver x11-xserver-utils xfonts-base debian-keyring debian-archive-keyring apt-transport-https curl nginx

# Install Wine staging
RUN mkdir -pm755 /etc/apt/keyrings \
    && wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key \
    && wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources \
    && apt update \
    && apt install --install-recommends winehq-stable cabextract wine-binfmt -y \
    && apt install -y surf openbox \
    && rm -rf /var/lib/apt/lists/*

# Set up Winetricks
RUN wget -q -O /usr/sbin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
    && chmod +x /usr/sbin/winetricks

# Install KasmVNC
RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    && wget https://github.com/kasmtech/KasmVNC/releases/download/v1.3.3/kasmvncserver_bookworm_1.3.3_amd64.deb \
    && apt --fix-broken install -y ./kasmvncserver_bookworm_1.3.3_amd64.deb \
    && rm -f kasmvncserver_bookworm_1.3.3_amd64.deb

# Set environment variables for Wine and VNC
ENV WINEPREFIX=/home/container/.wine
ENV WINEDLLOVERRIDES="mscoree,mshtml="
ENV DISPLAY=":1"

# Switch to container user
USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

COPY ./games/FarmingSimulator25/entrypoint.sh /entrypoint.sh

# Set the entrypoint
CMD [ "/bin/bash", "/entrypoint.sh" ]