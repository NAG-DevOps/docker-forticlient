FROM ubuntu:16.04

RUN apt-get update && \
  apt-get install -y expect wget net-tools iproute ipppd iptables ssh curl python2.7 && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /root

# Install fortivpn client unofficial .deb
RUN wget 'https://fortinet.egnyte.com/dd/ZGUGMw1Xxh/' -O forticlient-sslvpn_amd64.tar.gz
RUN tar xzvf forticlient-sslvpn_amd64.tar.gz

# Run setup
RUN echo "yes" > /root/forticlientsslvpn/64bit/helper/setup

# Copy runfiles
COPY forticlient /usr/bin/forticlient
COPY start.sh /start.sh
COPY imap.py /imap.py

CMD [ "/start.sh" ]
