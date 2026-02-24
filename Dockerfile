FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV container=docker

# Install systemd and required packages
RUN apt-get update && apt-get install -y \
    systemd \
    systemd-sysv \
    dbus \
    dbus-user-session \
    ca-certificates \
    tzdata \
    openssh-server \
    openssh-client \
    python3 \
    python3-pip \
    sudo \
    curl \
    wget \
    git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure systemd for container
RUN systemctl set-default multi-user.target && \
    systemctl mask \
        systemd-logind.service \
        systemd-remount-fs.service \
        getty.target \
        console-getty.service \
        systemd-udev-trigger.service \
        systemd-udevd.service \
        systemd-random-seed.service \
        systemd-machine-id-commit.service && \
    mkdir -p /var/run/sshd

# Create tmpfs mounts for systemd
RUN mkdir -p /run /run/lock /tmp && \
    chmod 1777 /tmp

# Create ansible user with sudoers access
RUN useradd -m -s /bin/bash ansible && \
    echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /home/ansible/.ssh && \
    chown -R ansible:ansible /home/ansible/.ssh && \
    chmod 700 /home/ansible/.ssh

# Copy authorized_keys if available (optional)
COPY --chown=ansible:ansible authorized_keys /home/ansible/.ssh/authorized_keys
RUN if [ -f /home/ansible/.ssh/authorized_keys ]; then \
      chmod 600 /home/ansible/.ssh/authorized_keys; \
    fi

# Configure SSH
RUN ssh-keygen -A && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Enable SSH service
RUN systemctl enable ssh

# Set up cgroups volume for systemd
VOLUME [ "/sys/fs/cgroup" ]

# Expose SSH port
EXPOSE 22

# Use systemd as init system
STOPSIGNAL SIGRTMIN+3
ENTRYPOINT ["/lib/systemd/systemd"]
