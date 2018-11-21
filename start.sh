#!/bin/sh

if [ -z "$VPNADDR" -o -z "$VPNUSER" -o -z "$VPNPASS" -o -z "$MAILPASSWORD" -o -z "$MAILUSER" -o -z "$MAILSERVER" ]; then
  echo "Variables VPNADDR, VPNUSER, VPNPASS, MAILSERVER, MAILUSER and MAILPASSWORD must be set."; exit;
fi

export VPNTIMEOUT=${VPNTIMEOUT:-5}

# Setup masquerade, to allow using the container as a gateway
for iface in $(ip a | grep eth | grep inet | awk '{print $2}'); do
  echo "$iface"
  iptables -t nat -A POSTROUTING -s "$iface" -j MASQUERADE
done


echo "------------ VPN Starts ------------"
/usr/bin/forticlient
echo "------------ VPN exited ------------"
