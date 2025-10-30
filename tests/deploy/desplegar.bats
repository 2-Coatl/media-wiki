#!/usr/bin/env bats

setup() {
  export REPO_ROOT="${BATS_TEST_DIRNAME}/../.."
  export TMP_WORKDIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$TMP_WORKDIR"
  unset REPO_ROOT
  unset TMP_WORKDIR
  unset DEPLOY_SECURITY_DIR
  unset DEPLOY_SECURITY_LOG
}

@test "desplegar: ejecuta rutinas de seguridad en orden" {
  stub_dir="$TMP_WORKDIR/security"
  mkdir -p "$stub_dir"

  order_file="$TMP_WORKDIR/orden.txt"
  export DEPLOY_SECURITY_DIR="$stub_dir"
  export DEPLOY_SECURITY_LOG="$order_file"

  scripts=(
    "harden-ssh.sh"
    "install-fail2ban.sh"
    "firewall-web.sh"
    "firewall-database.sh"
    "ssl-certificate.sh"
    "apache-ssl.sh"
    "harden-apache.sh"
  )

  for script in "${scripts[@]}"; do
    cat <<'SCRIPT' > "$stub_dir/$script"
#!/bin/bash
exit 0
SCRIPT
    chmod +x "$stub_dir/$script"
  done

  run "$REPO_ROOT/scripts/deploy/desplegar.sh"

  [ "$status" -eq 0 ]

  if [[ ! -f "$order_file" ]]; then
    echo "No se registraron ejecuciones de seguridad" >&2
    return 1
  fi

  executed=()
  while IFS= read -r line; do
    executed+=("$line")
  done < "$order_file"

  [ "${#executed[@]}" -eq "${#scripts[@]}" ]

  for i in "${!scripts[@]}"; do
    [ "${executed[$i]}" = "${scripts[$i]}" ]
  done
}
