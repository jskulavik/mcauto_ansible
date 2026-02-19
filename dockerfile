FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    openssh-server \
    python3 sudo && \
    mkdir /var/run/sshd

RUN useradd -m ansible && \
    echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY authorized_keys /home/ansible/.ssh/authorized_keys
RUN chown -R ansible:ansible /home/ansible/.ssh && chmod 600 /home/ansible/.ssh/authorized_keys

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]