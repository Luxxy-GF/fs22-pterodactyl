FROM  debian:bookworm-slim

ENV         DEBIAN_FRONTEND=noninteractive


RUN useradd -m -d /home/container -s /bin/bash container 

## install required packages
RUN             dpkg --add-architecture i386 \
    && apt update -y \
    && apt install -y --no-install-recommends gnupg2 iproute2 wget numactl tzdata software-properties-common libntlm0 winbind xvfb xauth python3 libncurses5:i386 libncurses6:i386 libsdl2-2.0-0 libsdl2-2.0-0:i386 tightvncserver x11-xserver-utils xfonts-base debian-keyring debian-archive-keyring apt-transport-https curl nginx


# Install wine staging
RUN             mkdir -pm755 /etc/apt/keyrings
RUN             wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
RUN             wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources
RUN             apt update
RUN             apt install --install-recommends winehq-stable cabextract wine-binfmt -y
RUN             apt install -y surf openbox
RUN             rm -rf /var/lib/apt/lists/*

# Set up Winetricks
RUN	            wget -q -O /usr/sbin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
    && chmod +x /usr/sbin/winetricks


ENV         WINEPREFIX=/home/container/.wine
ENV         WINEDLLOVERRIDES="mscoree,mshtml="
USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container


ENV DISPLAY=":1"

    
COPY            ./games/FarmingSimulator25/entrypoint.sh /entrypoint.sh
CMD             [ "/bin/bash", "/entrypoint.sh" ]