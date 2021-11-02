# forticlient

Connect to a FortiNet VPNs through docker

## Usage

The container uses the forticlientsslvpn_cli linux binary to manage ppp interface

This allows you to forward requests through the docker container as proxy on the VPN network.

### Windows

This should work with docker on windows, however with Windows 10 I see an issue with opening the vpn tunnel.

### Linux

```bash

# Start the priviledged docker container with a static ip
docker run -it --rm \
  --privileged \
  -p 3389:3389 \
  -p 3390:3390 \
  -e VPNADDR=host:port \
  -e VPNUSER=me@domain \
  -e VPNPASS=secret \
  -e DESTINATIONS="3089:192.168.1.2:3389|3090:192.168.1.3:3389" \
  -e Reconnect=true
  ghcr.io/jamescoverdale/forticlient-forwarder:latest
  
```

`Destinations` is a pipe `|` delimited string of destinations you want to forward to. This is then further colon `:` delimited to define the local port, host ip and host port. Definition of a `Local Port` allows you to forward to multiple hosts that use the same port as seen in the example (or even http/https hosts)

`LocalPort1:HostIP1:HostPort1|localPort2:HostIP2:HostPort2`

The above example would forward requests:
  
  `DockerIP:3389` to `192.168.1.2:3389`
  
  `DockerIP:3390` to `192.168.1.3:3389`
  
 This would allow you to RDP two different machines on the VPN network from your host machine, you can add as many destinations as you require.

## Misc

If you don't want to use a docker network, you can find out the container ip once it is started with:
```bash
# Find out the container IP
docker inspect --format '{{ .NetworkSettings.IPAddress }}' <container>

```

### Precompiled binaries

Thanks to [https://hadler.me](https://hadler.me/linux/forticlient-sslvpn-deb-packages/) for hosting up to date precompiled binaries which are used in this Dockerfile.
