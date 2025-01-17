# Self-Signed Certificate Generation Script

This script generates a self-signed Root CA certificate and server certificates, mimicking a real-world production
environment. It ensures that the certificates follow industry standards for TLS configurations.

## **Features**

- Generates a self-signed Root CA certificate.
- Creates server certificates signed by the Root CA.
- Combines the server and Root CA certificates into a full chain.
- Validates the generated certificates for correctness.

## **Requirements**

- OpenSSL installed on the host.
- Shell interpreter supporting POSIX `sh`.

## **Usage**

1. Clone the repository and navigate to the script directory.
2. Configure the necessary parameters in `DeployHub/scripts/generate_certificate.sh` and `DeployHub/certs/config/*.cnf`
   files.
3. Run the script:

```sh
cd DeployHub/scripts
./generate_certificate.sh
```

## **Directory Structure**

- `certs/`: Contains generated certificates and keys.
    - `vaultCA/`: Root CA files and server certificates.
    - `config/`: OpenSSL configuration files.
    - `database/`: Files required for the OpenSSL CA database.
- `scripts/`: Contains the main script and supporting files.

## **Output**

- Root CA Certificate: `certs/vaultCA/cacert.pem`
- Server Key: `certs/vaultCA/server/private_key.pem`
- Server Certificate: `certs/vaultCA/server/certificate.pem`
- Full Chain: `certs/vaultCA/server/intermediate_and_leaf_chain.bundle`

## **Validation**

- The script automatically validates:
    - The Root CA certificate.
    - The server certificate against the Root CA.
    - The full chain certificate.

## **Customization**

- Modify key size, passphrase, and expiration days in the script.
- Update SANs in `certs/config/server.cnf` for your environment.

## **Sharing .p12 Files with Private Keys**

The industry standard involves:

Generating a PKCS#12 (.p12) file that includes:
The client certificate.
The private key for that certificate.
The certificate chain (including intermediate and root CA certificates if applicable).
Securely sharing the .p12 file with the intended client systems or browsers.
The .p12 format ensures that the private key, certificate, and chain are bundled in one file. The file is often
protected with a strong password to ensure secure distribution.

## **Disclaimer**

This script is for testing and development purposes. Avoid using self-signed certificates in production environments
unless absolutely necessary.

## **License**

This script is open-source and can be freely modified and distributed.
