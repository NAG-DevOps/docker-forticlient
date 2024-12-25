FROM ubuntu:18.04

ENV TZ=America/Montreal
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN apt-get install -y ipppd expect wget net-tools ca-certificates iproute2 iptables ssh curl gnupg polipo && \
    apt-get install -y gcc-4.9 make libpam0g-dev libldap2-dev libssl-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /root

## Install fortivpn client unofficial .deb
#RUN wget 'https://hadler.me/files/forticlient-sslvpn_4.4.2332-1_amd64.deb' -O forticlient-sslvpn_amd64.deb
#RUN dpkg -x forticlient-sslvpn_amd64.deb /usr/share/forticlient

## Install official client
RUN wget --no-check-certificate -O- https://repo.fortinet.com/repo/7.0/ubuntu/DEB-GPG-KEY | apt-key add -
#RUN wget --no-check-certificate -vO - https://repo.fortinet.com/repo/7.0/ubuntu/DEB-GPG-KEY | gpg --dearmor > /usr/share/keyrings/fortinet-archive-keyring.gpg
RUN DEBIAN_FRONTEND=noninteractive echo "deb [arch=amd64] https://repo.fortinet.com/repo/7.0/ubuntu/ /bionic multiverse:" >> /etc/apt/sources.list \
    && apt-get update \
    && apt install forticlient \
    && apt-get clean

# Install SS5
RUN wget -O ss5.tar.gz "http://downloads.sourceforge.net/project/ss5/ss5/3.8.9-8/ss5-3.8.9-8.tar.gz"

RUN groupadd -r ss5 && useradd -r -g ss5 ss5 && \
  mkdir -p /usr/src/ss5 \
  && tar -xzf ss5.tar.gz -C /usr/src/ss5 --strip-components=1 \
  && rm ss5.tar.gz \
  && cd /usr/src/ss5 \
  && ln -s /usr/bin/gcc-4.9 /usr/bin/gcc && touch /usr/src/gcc \
  && ./configure \
  && make \
  && make install \
  && cd / \
  && rm /usr/src/gcc \
  && apt-get purge -y --auto-remove gcc-4.9 make libpam0g-dev libldap2-dev libssl-dev \
  && rm -rf /usr/src/ss5 \
  && sed -i "/#auth/a\auth 0.0.0.0\/0 - -" /etc/opt/ss5/ss5.conf \
  && sed -i "/#permit/a\permit - 0.0.0.0\/0 - 0.0.0.0\/0 - - - - -" /etc/opt/ss5/ss5.conf \
  && touch /var/log/ss5/ss5.log

RUN rm -rf /var/lib/apt/lists/*

# Run setup
RUN /usr/share/forticlient/opt/forticlient-sslvpn/64bit/helper/setup 2

# Copy runfiles
COPY forticlient /usr/bin/forticlient
COPY start.sh /start.sh
COPY imap.py /imap.py

EXPOSE 1080
EXPOSE 8123

CMD [ "/start.sh" ]
