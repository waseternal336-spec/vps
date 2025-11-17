FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Kolkata

ARG TAILSCALE_AUTHKEY="tskey-auth-kK6G9HkHkF11CNTRL-rFbFYV5cTtFfH4mHuFqVuFrcsUB53axqf"
ARG ROOT_PASSWORD="Darkboy336"

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      openssh-server \
      curl \
      wget \
      sudo \
      iptables \
      iproute2 \
    && rm -rf /var/lib/apt/lists/*

# Setup SSH
RUN echo "root:${ROOT_PASSWORD}" | chpasswd \
    && mkdir -p /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Install Tailscale - FIXED VERSION
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Create startup script
RUN cat > /start.sh << 'EOF'
#!/bin/bash

# Start SSH server
/usr/sbin/sshd

# Start tailscaled in background
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &

# Wait for tailscaled to start
sleep 5

# Authenticate and connect to Tailscale
tailscale up --authkey=${TAILSCALE_AUTHKEY} --hostname=zeabur-vps

# Show connection info
echo "=== Tailscale Status ==="
tailscale status
echo "=== Tailscale IP ==="
tailscale ip

# Keep container running
echo "=== SSH Server Ready ==="
echo "Connect using: ssh root@[tailscale-ip]"
echo "Password: ${ROOT_PASSWORD}"
sleep infinity
EOF

RUN chmod +x /start.sh

EXPOSE 22

# Use the startup script
CMD ["/start.sh"]
