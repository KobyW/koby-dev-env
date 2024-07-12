FROM debian:bullseye-slim

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Update and install necessary packages
RUN apt-get update && apt-get install -y \
    sudo \
    ssh \
    python3 \
    python3-pip \
    vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to the non-root user
USER testuser
WORKDIR /home/testuser

# Ensure parent directory exists for repo
RUN mkdir -p /home/testuser/koby-dev-env

# Copy init.sh and tasks.ini into the container
COPY configs/ /home/testuser/koby-dev-env/configs/
COPY util/ /home/testuser/koby-dev-env/util/
COPY env/ /home/testuser/koby-dev-env/env/
COPY init.sh /home/testuser/koby-dev-env/
COPY tasks.ini /home/testuser/koby-dev-env/

# Set the entry point to bash
CMD ["/bin/bash"]
