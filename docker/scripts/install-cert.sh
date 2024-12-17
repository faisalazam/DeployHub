#!/bin/sh

# Path to the PEM file and destination CRT file
CertPemFile="/certs/certificate.pem"
CertCrtFile="/usr/local/share/ca-certificates/certificate.crt"

# Check if the PEM file exists and if the CRT file is not already in place
if [ -f "$CertPemFile" ] && [ ! -f "$CertCrtFile" ]; then
    echo "[INFO] Installing custom certificate..."

    # Copy the PEM certificate to the system-wide CA certificates directory
    cp "$CertPemFile" "$CertCrtFile"

    # Update the CA certificates only if the certificate was copied
    update-ca-certificates
else
    if [ ! -f "$CertPemFile" ]; then
        echo "[ERROR] PEM certificate not found at $CertPemFile. Skipping installation."
    else
        echo "[INFO] Certificate already installed at $CertCrtFile. Skipping installation."
    fi
fi
