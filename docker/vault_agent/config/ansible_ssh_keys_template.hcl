template {
  contents = <<EOT
      {{ with secret "secret/data/ssh_keys/ansible" }}
      {{ .Data.data.id_rsa }}
    {{ end }}
  EOT
  destination = "/vault/secrets/auth/ansible/ssh_keys/${ENVIRONMENT}/id_rsa"
}

template {
  contents = <<EOT
      {{ with secret "secret/data/ssh_keys/ansible" }}
      {{ index .Data.data "id_rsa.pub" }}
    {{ end }}
  EOT
  destination = "/vault/secrets/auth/ansible/ssh_keys/${ENVIRONMENT}/id_rsa.pub"
}
