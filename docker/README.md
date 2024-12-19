Profiles:

When the default profile is active, all services (ansible, linux_ssh_pass_host, linux_ssh_keys_host) will run.
When CI profile is active, only the ansible service will run.

How to Run:

To start all services (e.g. local development):
`docker-compose up`

To start all services (e.g. local development):
`COMPOSE_PROFILES=default docker-compose up`

To start only the ansible service (e.g. CI):
`COMPOSE_PROFILES=CI docker-compose -f docker-compose.yml -f docker-compose-ci.override.yml up`

This setup ensures flexibility for local development and CI pipelines without duplicating configuration.

Testing the SSH Connection
From the ansible service, verify the SSH connection manually using the private key:
`docker exec -it ansible ssh -i /root/.ssh/id_rsa root@linux_ssh_keys_host -o StrictHostKeyChecking=no`

Generate keys:
`ssh-keygen -t rsa -b 4096 -f ../.ssh_keys/local/id_rsa -N ""`

Why REQUESTS_CA_BUNDLE is Important
When a self-signed certificate is used, tools such as requests or curl do not trust it by default. By setting the
REQUESTS_CA_BUNDLE to point to your trusted certificate file (e.g., /certs/certificate.pem), you allow these tools to
validate HTTPS connections using your certificate.


Generating .pem certificate:

```ps1
$CertPath = "..\certs\local"
$CertPemExportFileName = "certificate.pem"

# $cert = your certificate to extract the pem from, e.g.;
# $cert = New-SelfSignedCertificate ......

# Export the public certificate to a .pem file (for Ansible Container)
$CertPemFile = Join-Path $CertPath "$CertPemExportFileName"
Write-Log -message "Exporting the certificate to PEM file: $CertPemFile"

# Export the public certificate to PEM format
Set-Content -Path $CertPemFile -Value @(
    "-----BEGIN CERTIFICATE-----"
    [Convert]::ToBase64String($cert.RawData) -replace ".{64}", "$&`n"
    "-----END CERTIFICATE-----"
)

Write-Log -message "Certificate exported successfully to PEM file: $CertPemFile"
```