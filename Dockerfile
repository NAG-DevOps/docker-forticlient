FROM ubuntu:18.04

RUN apt-get update && \
  apt-get install -y expect wget net-tools iproute ipppd iptables ssh curl && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /root

## Install fortivpn client unofficial .deb
#RUN wget 'https://hadler.me/files/forticlient-sslvpn_4.4.2329-1_amd64.deb' -O forticlient-sslvpn_amd64.deb
#RUN dpkg -x forticlient-sslvpn_amd64.deb /usr/share/forticlient

## Install official client
RUN wget -O - https://repo.fortinet.com/repo/7.0/ubuntu/DEB-GPG-KEY | sudo apt-key add -
RUN echo "deb [arch=amd64] https://repo.fortinet.com/repo/6.4/ubuntu/ /bionic multiverse: >> /etc/apt/sources.list
    && apt-get update \
    && apt install forticlient \
    && apt-get clean

### Run setup
##RUN /usr/share/forticlient/opt/forticlient-sslvpn/64bit/helper/setup.linux.sh 2

# Copy runfiles
COPY forticlient /usr/bin/forticlient
COPY start.sh /start.sh

CMD [ "/start.sh" ]
