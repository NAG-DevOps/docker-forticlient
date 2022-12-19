FROM ubuntu:18.04

ENV TZ=America/Montreal
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#  apt-get install -y expect wget net-tools iproute2 ipppd iptables ssh curl && \

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
  apt-get install -y expect wget net-tools iproute2 iptables ssh curl && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /root

## Install fortivpn client unofficial .deb
#RUN wget 'https://hadler.me/files/forticlient-sslvpn_4.4.2329-1_amd64.deb' -O forticlient-sslvpn_amd64.deb
#RUN dpkg -x forticlient-sslvpn_amd64.deb /usr/share/forticlient

## Install official client
RUN wget -O - https://repo.fortinet.com/repo/7.0/ubuntu/DEB-GPG-KEY | sudo apt-key add -
RUN DEBIAN_FRONTEND=noninteractive echo "deb [arch=amd64] https://repo.fortinet.com/repo/7.0/ubuntu/ /bionic multiverse:" >> /etc/apt/sources.list \
    && apt-get update \
    && apt install forticlient \
    && apt-get clean

### Run setup
##RUN /usr/share/forticlient/opt/forticlient-sslvpn/64bit/helper/setup.linux.sh 2

# Copy runfiles
COPY forticlient /usr/bin/forticlient
COPY start.sh /start.sh

CMD [ "/start.sh" ]
