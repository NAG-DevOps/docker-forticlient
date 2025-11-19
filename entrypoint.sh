#!/bin/bash
# Entrypoint script for FortiClient VPN container
# Supports both VPN-only mode and XFCE4 desktop mode

set -e

# Default mode: VPN only
MODE="${MODE:-vpn}"

# Function to start dbus and xfce4 session
start_desktop() {
    echo "Starting XFCE4 desktop environment..."
    
    # Reduce accessibility-related noisy warnings when running in container
    export NO_AT_BRIDGE=1
    export GTK_MODULES=

    # Decide whether to use host DISPLAY or start a nested X server
    HOST_DISPLAY="${DISPLAY:-}" 
    if [ -n "$HOST_DISPLAY" ]; then
        # If host X server is running, avoid replacing its window manager
        if command -v xdpyinfo >/dev/null 2>&1 && xdpyinfo -display "$HOST_DISPLAY" >/dev/null 2>&1; then
            echo "Detected host X server on $HOST_DISPLAY. Starting nested Xephyr on :1 to avoid conflicts."
            # Start nested X server (Xephyr) on :1
            Xephyr -br -noreset -screen 1280x800 :1 &
            # wait for nested X
            for i in $(seq 1 20); do
                xdpyinfo -display :1 >/dev/null 2>&1 && break || sleep 0.5
            done
            export DISPLAY=":1"
        else
            export DISPLAY="$HOST_DISPLAY"
        fi
    else
        # No host DISPLAY: start a virtual framebuffer
        echo "No DISPLAY detected. Starting Xvfb on :1"
        Xvfb :1 -screen 0 1280x800x24 &
        for i in $(seq 1 20); do
            xdpyinfo -display :1 >/dev/null 2>&1 && break || sleep 0.5
        done
        export DISPLAY=":1"
    fi

    # Start dbus session
    eval $(dbus-launch --sh-syntax) || true
    export DBUS_SESSION_BUS_ADDRESS
    
    # Start background services before XFCE4
    echo "Starting FortiClient VPN..."
    /usr/bin/forticlient &
    FORTICLIENT_PID=$!
    
    # Start Dante SOCKS5 server
    echo "Starting Dante SOCKS5 proxy..."
    /usr/sbin/danted -f /etc/danted.conf &
    DANTE_PID=$!
    
    # Start tinyproxy HTTP proxy
    echo "Starting tinyproxy HTTP proxy..."
    /usr/sbin/tinyproxy -d &
    TINYPROXY_PID=$!
    
    # Start XFCE4 session on the chosen DISPLAY
    echo "Starting XFCE4 session on $DISPLAY..."
    exec startxfce4 --replace
}

# Function to start VPN-only mode (original behavior)
start_vpn_only() {
    echo "Starting in VPN-only mode..."
    
    # Run original start.sh logic
    exec /start.sh
}

# Main routing logic
case "$MODE" in
    desktop|xfce)
        start_desktop
        ;;
    vpn|vpn-only)
        start_vpn_only
        ;;
    *)
        echo "Unknown mode: $MODE"
        echo "Valid modes: vpn (default), desktop, xfce"
        exit 1
        ;;
esac
