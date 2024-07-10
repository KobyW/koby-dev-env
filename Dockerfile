FROM debian:bullseye-slim

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Update and install necessary packages
RUN apt-get update && apt-get install -y \
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to the non-root user
USER testuser
WORKDIR /home/testuser

# Create a directory for your dotfiles
RUN mkdir -p /home/testuser/dotfiles

# Copy init.sh and tasks.txt into the container
COPY init.sh /home/testuser/koby-dev-env/
COPY tasks.txt /home/testuser/koby-dev-env/

# Make sure the script is executable
RUN chmod +x /home/testuser/dotfiles/init.sh

# Set the entry point to bash
CMD ["/bin/bash"]
