#!/usr/bin/env bash
set -euo pipefail

SSH_DIR="${HOME}/.ssh"
SSH_CONFIG="${SSH_DIR}/config"
KNOWN_HOSTS="${SSH_DIR}/known_hosts"
BEGIN_MARKER="# >>> codex github ssh 443 >>>"
END_MARKER="# <<< codex github ssh 443 <<<"

mkdir -p "${SSH_DIR}"
chmod 700 "${SSH_DIR}"
touch "${KNOWN_HOSTS}"
chmod 600 "${KNOWN_HOSTS}"

managed_block() {
  cat <<'EOF'
# >>> codex github ssh 443 >>>
Host github.com
    HostName ssh.github.com
    Port 443
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
# <<< codex github ssh 443 <<<
EOF
}

install_ssh_config_block() {
  local tmp_file
  tmp_file="$(mktemp)"

  if [[ -f "${SSH_CONFIG}" ]] && grep -Fq "${BEGIN_MARKER}" "${SSH_CONFIG}"; then
    awk -v begin="${BEGIN_MARKER}" -v end="${END_MARKER}" '
      $0 == begin {skip=1; next}
      $0 == end {skip=0; next}
      !skip {print}
    ' "${SSH_CONFIG}" > "${tmp_file}"

    {
      managed_block
      cat "${tmp_file}"
    } > "${SSH_CONFIG}"
  elif [[ -f "${SSH_CONFIG}" ]]; then
    {
      managed_block
      cat "${SSH_CONFIG}"
    } > "${tmp_file}"
    mv "${tmp_file}" "${SSH_CONFIG}"
  else
    managed_block > "${SSH_CONFIG}"
  fi

  chmod 600 "${SSH_CONFIG}"
  rm -f "${tmp_file}" 2>/dev/null || true
}

ensure_known_host() {
  if ! ssh-keygen -F "[ssh.github.com]:443" -f "${KNOWN_HOSTS}" >/dev/null 2>&1; then
    ssh-keyscan -p 443 ssh.github.com >> "${KNOWN_HOSTS}"
    chmod 600 "${KNOWN_HOSTS}"
  fi
}

configure_git_rewrite() {
  git config --global --unset-all url."ssh://git@github.com/".insteadOf >/dev/null 2>&1 || true
  git config --global --add url."ssh://git@github.com/".insteadOf https://github.com/
  git config --global --add url."ssh://git@github.com/".insteadOf http://github.com/
}

test_github_ssh() {
  local rc
  set +e
  ssh -T git@github.com
  rc=$?
  set -e

  if [[ "${rc}" -ne 0 && "${rc}" -ne 1 ]]; then
    echo "GitHub SSH test failed with exit code ${rc}" >&2
    return "${rc}"
  fi
}

install_ssh_config_block
ensure_known_host
configure_git_rewrite
test_github_ssh

cat <<'EOF'
Global GitHub SSH-over-443 configuration is installed.

What changed:
- ~/.ssh/config now routes github.com to ssh.github.com:443
- ~/.ssh/known_hosts now includes ssh.github.com:443
- git config --global now rewrites https://github.com/... to ssh://git@github.com/...

Effect:
- Existing repos with GitHub HTTPS remotes can push/pull through SSH 443
- New git clone https://github.com/... commands will also use SSH 443
EOF
