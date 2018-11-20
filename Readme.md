# forticlient

Connect to a FortiNet VPNs through docker

## Usage

The container uses the forticlientsslvpn_cli linux binary to manage ppp interface

This allows the user to RDP to the docker host with the specified port, which will then be forwarded to the docker container running the vpn, and finally redirected to the remote machine you wish to connect to (set by VPNRDPIP).

If running the docker container from the machine you wish to connect from you can omit the -p settings, and connect to the ip address of the container on port 3380.

### Windows

This should work with docker on windows, however with Windows 10 I see an issue with opening the vpn tunnel.

### Linux

```bash

# Start the priviledged docker container with a static ip
docker run -it --rm \
  --privileged \
  -p 1234:3380 \
  -e VPNADDR=host:port \
  -e VPNUSER=me@domain \
  -e VPNPASS=secret \
  -e VPNRDPIP=ipofRDPmachine \
  -e Reconnect=true
  cadab/docker-forticlient

```

## Misc

If you don't want to use a docker network, you can find out the container ip once it is started with:
```bash
# Find out the container IP
docker inspect --format '{{ .NetworkSettings.IPAddress }}' <container>

```

### Precompiled binaries

Thanks to [https://hadler.me](https://hadler.me/linux/forticlient-sslvpn-deb-packages/) for hosting up to date precompiled binaries which are used in this Dockerfile.
