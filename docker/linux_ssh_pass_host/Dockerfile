# Use Ubuntu 24.04 as the base image
# docker build -f ./Dockerfile -t linux_ssh_pass_host .
FROM ubuntu:24.04

# Install SSH server and required dependencies
RUN apt-get update && \
    apt-get install -y openssh-server python3 && \
    mkdir /var/run/sshd && \
    # Generate a hashed password for root using Python
    python3 -c 'import crypt; print(crypt.crypt("rootpassword", crypt.mksalt(crypt.METHOD_SHA512)))' > /tmp/root_hashed_password && \
    sed -i "s|^root:.*|root:$(cat /tmp/root_hashed_password):19000:0:99999:7:::|" /etc/shadow && \
    rm /tmp/root_hashed_password && \
    # Configure SSH for root login
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    sed -i 's/^#ListenAddress.*/ListenAddress 0.0.0.0/' /etc/ssh/sshd_config && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Expose SSH port
EXPOSE 22

# Start SSH service by default
CMD ["/usr/sbin/sshd", "-D"]
