# Placeholder for README.md

For Shell Scripts: Windows-style line endings (CRLF) can cause syntax errors because they are interpreted as extra
characters in Unix-based systems, leading to "command not found" errors.

For SSH Keys: SSH keys must be treated as binary files to avoid corruption. Any unintended modification (like adding or
removing \r characters) renders the key invalid, triggering libcrypto errors.

e.g. `Load key \"/root/.ssh/id_rsa\": error in libcrypto\r\nroot@linux_ssh_keys_host`

Adding .sh and keys to .gitattributes ensures that all developers and systems interacting with your repository use the
correct line endings, preventing future issues.

Clear the core.autocrlf setting in Git: Git's core.autocrlf setting may still be altering the line endings, especially if it's set to true or input. Set it to false to prevent any automatic conversion:

`git config --global core.autocrlf false`

Explanation:

core.autocrlf=true automatically converts LF to CRLF on checkout (in Windows).
core.autocrlf=input ensures that CRLF is converted to LF on commit but doesn't affect checkouts.
core.autocrlf=false ensures no conversion is done at all (both on commit and checkout).