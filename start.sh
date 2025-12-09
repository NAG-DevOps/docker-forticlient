#!/bin/sh

# ==============================================================================
# !!! FOR DOCKER STARTUP:
# 
# When running the Docker container with this script, you MUST use specific 
# flags to grant necessary privileges and network capabilities.
#
# Recommended flags for 'docker run':
# 
#   --privileged 
#     OR (better): 
#   --cap-add=NET_ADMIN --device=/dev/ppp 
#
# Examples of mandatory Environment Variables to set:
#   -e VPNADDR="vpn.example.com:10443"
#   -e VPNUSER="user@domain"
#   -e VPNPASS="password123"
#   -e DESTINATIONS="1080:172.20.0.3:1080|8123:172.20.0.3:8123"
# ==============================================================================

# Enable verbose mode: prints all commands to standard output before execution
set -x

# --- Mandatory Variable Checks ---
# Ensure essential variables for the VPN connection are provided.
if [ -z "$VPNADDR" ] || [ -z "$VPNUSER" ] || [ -z "$VPNPASS" ] || [ -z "$DESTINATIONS" ]; then 
  echo "Error: Mandatory variables VPNADDR, VPNUSER, VPNPASS, and DESTINATIONS must be set."; 
  echo "Format for DESTINATIONS: localPort1:host1:destPort1|localPort2:host2:destPort2";
  exit 1;
fi

# --- Optional Variable Setup with Defaults ---
# Set timeouts and paths, using defaults if environment variables are not provided.
export VPNTIMEOUT=${VPNTIMEOUT:-5}
export CONNECTION_ESTABLISHED=${CONNECTION_ESTABLISHED:-"/tmp/success"}
# Export VPNTOKEN if provided, otherwise leave it empty.
export VPNTOKEN=${VPNTOKEN:-""} 
# Set the reconnect behavior default to "true".
export Reconnect=${Reconnect:-"true"}

echo "Configuring NAT/iptables rules..."

# --- Configure Port Redirections (iptables PREROUTING) ---
# Iterate over the destinations defined in the DESTINATIONS variable
for i in $(echo $DESTINATIONS | tr "|" "\n")
do	
    # Parse the local port, destination host, and destination port
	localport="$(echo $i | cut -d':' -f1)"
	host="$(echo $i | cut -d':' -f2)"
	destport="$(echo $i | cut -d':' -f3)"
	echo "Setting forward rule: $localport -> $host:$destport"
    # Add the NAT rule to redirect incoming traffic
	iptables -t nat -A PREROUTING -p tcp --dport $localport -j DNAT --to-destination $host:$destport  
done

# --- Configure Masquerade (iptables POSTROUTING) ---
# Allow internal network traffic to be routed out via the container's main interface
iptables -t nat -A POSTROUTING -j MASQUERADE

# Setup masquerade specifically for standard eth interfaces
for iface in $(ip a | grep eth | grep inet | awk '{print $2}'); do
  echo "$0: Setting masquerade for interface: $iface"
  iptables -t nat -A POSTROUTING -s "$iface" -j MASQUERADE
done

# --- System Setup ---
# Create the ppp device node required for VPN tunneling
mknod /dev/ppp c 108 0

# --- Main VPN Loop ---
# Start the FortiClient and handle reconnections
while [ true ]; do
  echo "------------ VPN Starts ------------"
  # Execute the FortiClient binary (it should pick up env variables set above)
  /usr/bin/forticlient
  echo "------------ VPN Exited ------------"
  sleep 10
  
  # Check if reconnection is desired (case-insensitive check)
  if [ "$(echo "$Reconnect" | tr '[:upper:]' '[:lower:]')" != "true" ]; then
    echo "$0: Reconnect=$Reconnect: exiting script based on configuration..."
    exit 0;
  fi
  
done
