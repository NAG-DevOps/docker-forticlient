FROM ubuntu:26.04

ENV TZ=America/Montreal
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /root

# Install build dependencies and runtime packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc make libpam0g-dev libldap2-dev libssl-dev \
    wget ca-certificates gnupg && \
    rm -rf /var/lib/apt/lists/*

### Install FortiClient 7.4 from official repository
### Use gpg --dearmor to handle GPG key importing for newer Ubuntu versions
RUN wget -O - https://repo.fortinet.com/repo/forticlient/7.4/ubuntu22/DEB-GPG-KEY | gpg --dearmor | tee /usr/share/keyrings/repo.fortinet.com.gpg && \
    DEBIAN_FRONTEND=noninteractive echo "deb [arch=amd64 signed-by=/usr/share/keyrings/repo.fortinet.com.gpg] https://repo.fortinet.com/repo/forticlient/7.4/ubuntu22/ stable non-free" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends forticlient && \
    rm -rf /var/lib/apt/lists/*

# Install runtime dependencies and minimal XFCE4 desktop
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --no-install-recommends \
    tinyproxy expect wget net-tools ca-certificates iproute2 iptables ssh curl \
    xdg-utils libnss3 libasound2 libgconf-2-4 libgtk-3-0 libuuid1 libsecret-1-0 \
    xfce4 xfce4-terminal xfce4-panel xfce4-session xfce4-settings thunar \
    xfce4-whiskermenu-plugin dbus dbus-x11 x11-utils xauth \
    libcanberra-gtk-module libcanberra-gtk3-module libcanberra0 libnotify-bin \
    policykit-1 at-spi2-core pm-utils \
    xserver-xephyr xvfb x11vnc pulseaudio-utils libpulse0 x11-xserver-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

### Install Dante SOCKS5 server (modern alternative to SS5)
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --no-install-recommends dante-server && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/log/dante && \
    chown -R nobody:nogroup /var/log/dante

# Configure Dante SOCKS5 server
RUN echo "# Dante SOCKS5 configuration" > /etc/danted.conf && \
    echo "internal: 0.0.0.0 port = 1080" >> /etc/danted.conf && \
    echo "external: 0.0.0.0" >> /etc/danted.conf && \
    echo "" >> /etc/danted.conf && \
    echo "client pass {" >> /etc/danted.conf && \
    echo "    from: 0.0.0.0/0 to: 0.0.0.0/0" >> /etc/danted.conf && \
    echo "}" >> /etc/danted.conf && \
    echo "" >> /etc/danted.conf && \
    echo "socks pass {" >> /etc/danted.conf && \
    echo "    from: 0.0.0.0/0 to: 0.0.0.0/0" >> /etc/danted.conf && \
    echo "}" >> /etc/danted.conf

# Configure tinyproxy for HTTP proxy on port 8123
RUN sed -i 's/^Port 8888/Port 8123/' /etc/tinyproxy/tinyproxy.conf && \
    sed -i 's/^# Allow 127.0.0.1/Allow 0.0.0.0\/0/' /etc/tinyproxy/tinyproxy.conf

# Copy runfiles (These files need to be present in your local directory when building)
COPY forticlient /usr/bin/forticlient
COPY start.sh /start.sh
COPY imap.py /imap.py
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose ports: 1080 (Dante SOCKS5), 8123 (tinyproxy HTTP), VPN tunnel interface
EXPOSE 1080
EXPOSE 8123

CMD [ "/entrypoint.sh" ]
