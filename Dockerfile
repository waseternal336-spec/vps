FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Kolkata

ARG TAILSCALE_AUTHKEY="tskey-auth-kK6G9HkHkF11CNTRL-rFbFYV5cTtFfH4mHuFqVuFrcsUB53axqf"
ARG ROOT_PASSWORD="Darkboy336"

# Install minimal tools and tzdata
RUN apt-get update && \
    apt-get install -y --no-install-recommends apt-utils ca-certificates gnupg2 curl wget lsb-release tzdata && \
    ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    rm -rf /var/lib/apt/lists/*

# Install common utilities, SSH, and software-properties-common
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      openssh-server \
      wget \
      curl \
      git \
      nano \
      sudo \
      software-properties-common \
      iptables \
    && rm -rf /var/lib/apt/lists/*

# Python 3.12
RUN add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    apt-get install -y --no-install-recommends python3.12 python3.12-venv && \
    rm -rf /var/lib/apt/lists/*

# Make python3 point to python3.12
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

# SSH root password
RUN echo "root:${ROOT_PASSWORD}" | chpasswd \
    && mkdir -p /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config || true \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config || true

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Optional hostname file
RUN echo "Dark" > /etc/hostname

# Force bash prompt
RUN echo 'export PS1="root@Dark:\\w# "' >> /root/.bashrc

EXPOSE 22

# Start sshd and Tailscale
CMD ["sh", "-c", "/usr/sbin/sshd && tailscale up --authkey=${TAILSCALE_AUTHKEY} --hostname=zeabur-vps && tailscale ip && tailscale status && sleep infinity"]
