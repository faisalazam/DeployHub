# Integrate `ssh-keygen` into Vault container using multi-stage build
# This approach enhances security and performance by keeping the Vault image minimal
# while meeting the key generation requirements.
# Stage 1: Use an image with ssh-keygen
FROM alpine:3.21 AS builder
RUN apk add --no-cache openssh

# Stage 2: Use Vault image
FROM hashicorp/vault:1.18.3
COPY --from=builder /usr/bin/ssh-keygen /usr/bin/ssh-keygen

CMD ["sh", "-c", "vault --version"]
