# Forticlient VPN

Connect to a FortiNet VPNs through docker

## Usage

The container uses the forticlientsslvpn_cli linux binary to manage ppp interface.
This allows you to forward requests through the docker container as proxy on the VPN network.
All of the container traffic is routed through the VPN, so you can in turn route host traffic through the container to access remote subnets.

### Linux

```bash
# Create a docker network, to be able to control addresses
docker network create --subnet=172.20.0.0/16 fortinet

# Start the priviledged docker container with a static ip
docker run -it --rm \
  --privileged \
  --net fortinet --ip 172.20.0.2 \
  -e VPNADDR=address:port \
  -e VPNUSER=user@name \
  -e VPNPASS='password' \
  -p 11080:1080 \
  -p 18123:8123 \
  -e MAILUSER=user@mail \
  -e MAILPASSWORD=email_pass \
  -e MAILSERVER=mail_server \
  NAG-DevOps/forticlient-with-proxy

# Add route for you remote subnet (ex. 10.201.0.0/16)
ip route add 10.201.0.0/16 via 172.20.0.2

# Access remote host from the subnet
ssh 10.201.8.1
```

`Destinations` is a pipe `|` delimited string of destinations you want to forward to. This is then further colon `:` delimited to define the local port, host ip and host port. Definition of a `Local Port` allows you to forward to multiple hosts that use the same port as seen in the example (or even http/https hosts)

`LocalPort1:HostIP1:HostPort1|localPort2:HostIP2:HostPort2`

The above example would forward requests:
  
  `DockerIP:3389` to `192.168.1.2:3389`
  
  `DockerIP:3390` to `192.168.1.3:3389`
  
This would allow you to RDP two different machines on the VPN network from your host machine, you can add as many destinations as you require.

### Only Proxy

```bash
# Start the priviledged docker container on its host network
docker run -it --rm \
  --privileged \
  -e VPNADDR=address:port \
  -e VPNUSER=user@name \
  -e VPNPASS='password' \
  -p 11080:1080 \
  -p 18123:8123 \
  -e MAILUSER=user@mail \
  -e MAILPASSWORD=email_pass \
  -e MAILSERVER=mail_server \
  -p 11080:1080 \
  -p 18123:8123 \
  -e VPNTOKEN=token \
  NAG-DevOps/forticlient-with-proxy
```

Docker will start two proxies, 1080 for socks5 and 8123 for http.


### Windows (outdated)

This should work with docker on Windows, however with Windows 10 I see an issue with opening the vpn tunnel.

### macOS (outdated)

Docker Beta's kernel lasks ppp interface support, so you'll need to use a docker-machine VM

```bash
# Create a docker-machine and configure shell to use it
docker-machine create fortinet --driver virtualbox
eval $(docker-machine env fortinet)

# Start the priviledged docker container
docker run -it --rm \
  --privileged --net host \
 -e VPNADDR=address:port \
  -e VPNUSER=user@name \
  -e VPNPASS='password' \
  -p 11080:1080 \
  -p 18123:8123 \
  -e MAILUSER=user@mail \
  -e MAILPASSWORD=email_pass \
  -e MAILSERVER=mail_server \
  NAG-DevOps/forticlient

# Add route for you remote subnet (ex. 10.201.0.0/16)
sudo route add -net 10.201.0.0/16 $(docker-machine ip fortinet)

# Access remote host from the subnet
ssh 10.201.8.1
```

## Misc

If you don't want to use a docker network, you can find out the container ip once it is started with:
```bash
# Find out the container IP
docker inspect --format '{{ .NetworkSettings.IPAddress }}' <container>

```

### Precompiled binaries

- https://repo.fortinet.com/
- Locally provided by the organization (.deb or .rpm) for EMS

### References and thanks

- This fork is based on several forks of this repo combining their features deemed useful:
  - [jamescoverdale](https://github.com/jamescoverdale/docker-forticlient)
  - [yuga-92](https://github.com/yuga-92/docker-forticlient)
  - [AuchanDirect](https://github.com/AuchanDirect/docker-forticlient)
  - [DeanF](https://github.com/DeanF/docker-forticlient)
  - [henry42](https://github.com/henry42/docker-forticlient-with-proxy/)
  - [siwaonline](https://github.com/siwaonline/docker-forticlient) for the base images and idea.

- FortiClient
  - [Fortinet documentation on downloaing the official client](https://www.fortinet.com/support/product-downloads/linux)
  - [CLI](https://docs.fortinet.com/document/forticlient/7.4.1/administration-guide/041299/forticlient-linux-cli-commands)
  - [Repo Install](https://repo.fortinet.com/)
  - [File Install](https://docs.fortinet.com/document/forticlient/7.4.2/administration-guide/437544/installing-forticlient-linux-using-a-downloaded-installation-file)
