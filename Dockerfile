FROM debian:bullseye-slim

ARG USER=${USER}

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Update and install necessary packages
RUN apt-get update && apt-get install -y \
    sudo \
    ssh \
    openssh-server \
    python3 \
    python3-pip \
    vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Setup running user on the container with sudo rights and
# password-less ssh login
RUN useradd -m ${USER}
RUN adduser ${USER} sudo
RUN echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/sudoers

# As the user setup the ssh identity using the key in the tmp folder
USER "${USER}"
RUN mkdir ~/.ssh
RUN chmod -R 700 ~/.ssh
COPY --chown=${USER}:sudo id_rsa.pub /home/${USER}/.ssh/id_rsa.pub
RUN cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
RUN chmod 644 ~/.ssh/id_rsa.pub
RUN chmod 644 ~/.ssh/authorized_keys

# start ssh with port exposed
USER root
RUN service ssh start

# Expose the ssh port
EXPOSE 22

# Set the entry point to bash
CMD ["/usr/sbin/sshd", "-D"]
