FROM ubuntu:rolling AS builder
ENV GOLANG_VERSION=1.23.4
ENV CTOP_VERSION=0.7.7
ENV CALICOCTL_VERSION=3.29.1
ENV TERMSHARK_VERSION=2.4.0

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y full-upgrade && \
    apt-get -y autoremove && \
    apt-get -y autoclean && \
    apt-get -y clean && \
    apt-get -y install build-essential curl git golang wget

# Download and build ctop
RUN wget https://github.com/bcicen/ctop/archive/refs/tags/v${CTOP_VERSION}.tar.gz && \
    tar -xzf v${CTOP_VERSION}.tar.gz && \
    cd ctop-${CTOP_VERSION} && \
    make build && \
    install -m 0755 ctop /usr/local/bin/ctop

# Download and install calicoctl
# Installing calicoctl
RUN wget https://github.com/projectcalico/calico/releases/download/v${CALICOCTL_VERSION}/calicoctl-linux-$(dpkg --print-architecture) -O /usr/local/bin/calicoctl && \
    chmod 0755 /usr/local/bin/calicoctl

#
# End builder stage
#

# Final stage
FROM alpine:3.21
RUN set -ex && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories  && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk update && \
    apk upgrade && \
    apk add --no-cache \
    apache2-utils \
    bash \
    bind-tools \
    bird \
    bridge-utils \
    busybox-extras \
    conntrack-tools \
    curl \
    dhcping \
    drill \
    ethtool \
    file\
    fping \
    go \
    iftop \
    iperf \
    iperf3 \
    iproute2 \
    ipset \
    iptables \
    iptraf-ng \
    iputils \
    ipvsadm \
    httpie \
    jq \
    libc6-compat \
    liboping \
    ltrace \
    mtr \
    net-snmp-tools \
    netcat-openbsd \
    nftables \
    ngrep \
    nmap \
    nmap-nping \
    nmap-scripts \
    openssl \
    py3-pip \
    py3-setuptools \
    scapy \
    socat \
    speedtest-cli \
    openssh \
    oh-my-zsh \
    strace \
    tcpdump \
    tcptraceroute \
    tshark \
    util-linux \
    vim \
    git \
    zsh \
    websocat \
    swaks \
    perl-crypt-ssleay \
    perl-net-ssleay

# apparmor issue #14140 - No longer needed with Alpine 3.21+ image
#RUN mv /usr/sbin/tcpdump /usr/bin/tcpdump

# Install termshark, grpcurl, and fortio
RUN GO111MODULE=on go install github.com/gcla/termshark/v2/cmd/termshark@latest && \
    GO111MODULE=on go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest && \
    GO111MODULE=on go install fortio.org/fortio@latest

COPY --from=builder /usr/local/bin/ctop /usr/local/bin/ctop
COPY --from=builder /usr/local/bin/calicoctl /usr/local/bin/calicoctl

# Setting User and Home
USER root
WORKDIR /root
ENV HOSTNAME=netshoot

# ZSH Themes
RUN curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh && \
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
COPY zshrc .zshrc
COPY motd motd

# Fix permissions for OpenShift and tshark
RUN chmod -R g=u /root
RUN chown root:root /usr/bin/dumpcap

# Running ZSH
CMD ["zsh"]
