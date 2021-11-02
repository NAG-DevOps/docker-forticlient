#!/bin/sh

if [ -z "$VPNADDR" -o -z "$VPNUSER" -o -z "$VPNPASS" -o -z "$DESTINATIONS" ]; then
  echo "Variables DESTINATIONS (localPort1:host1:destPort1|localPort2:host2:destPort2), VPNADDR, VPNUSER and VPNPASS must be set."; exit;
fi

export VPNTIMEOUT=${VPNTIMEOUT:-5}

for i in $(echo $DESTINATIONS | tr "|" "\n")
do	
	localport="$(echo $i | cut -d':' -f1)"
	host="$(echo $i | cut -d':' -f2)"
	destport="$(echo $i | cut -d':' -f3)"
	echo "Setting forward for $localport -> $host:$destport"
	iptables -t nat -A PREROUTING -p tcp --dport $localport -j DNAT --to-destination $host:$destport  
done

iptables -t nat -A POSTROUTING -j MASQUERADE

# Setup masquerade, to allow using the container as a gateway
for iface in $(ip a | grep eth | grep inet | awk '{print $2}'); do
  iptables -t nat -A POSTROUTING -s "$iface" -j MASQUERADE
done

 mknod /dev/ppp c 108 0

while [ true ]; do
  echo "------------ VPN Starts ------------"
  /usr/bin/forticlient
  echo "------------ VPN exited ------------"
  sleep 10
  
  #If not set then exit
  if [ $Reconnect != "true" ] || [ $Reconnect != "TRUE" ]; then
    exit;
  fi
  
done
