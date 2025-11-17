FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Kolkata

ARG NGROK_AUTHTOKEN="30Xt1F8pXJpc2no2LdQF4xqrmjT_7rUnMXDivp3iiAKpV1fAc"
ARG ROOT_PASSWORD="Darkboy336"

# Install minimal tools and tzdata
RUN apt-get update && \
    apt-get install -y --no-install-recommends apt-utils ca-certificates gnupg2 curl wget lsb-release tzdata && \
    ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    rm -rf /var/lib/apt/lists/*

# Install common utilities, SSH, and software-properties-common for add-apt-repository
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      openssh-server \
      wget \
      curl \
      git \
      nano \
      sudo \
      software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Python 3.12 - FIXED: added software-properties-common above
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

# ngrok official repo
RUN curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
    && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | tee /etc/apt/sources.list.d/ngrok.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends ngrok \
    && rm -rf /var/lib/apt/lists/*

# Add ngrok token
RUN if [ -n "${NGROK_AUTHTOKEN}" ]; then ngrok config add-authtoken "${NGROK_AUTHTOKEN}"; fi

# Optional hostname file
RUN echo "Dark" > /etc/hostname

# Force bash prompt
RUN echo 'export PS1="root@Dark:\\w# "' >> /root/.bashrc

EXPOSE 22

# Start sshd and ngrok (foreground)
CMD ["sh", "-c", "/usr/sbin/sshd && ngrok tcp 22 --log=stdout"]
