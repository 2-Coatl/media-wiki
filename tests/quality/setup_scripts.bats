#!/usr/bin/env bats

setup() {
  export REPO_ROOT="${BATS_TEST_DIRNAME}/../.."
  export TMP_WORKDIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$TMP_WORKDIR"
  unset REPO_ROOT
  unset TMP_WORKDIR
}

@test "validate-host: éxito con dependencias inyectadas" {
  stub_dir="$TMP_WORKDIR/stubs"
  mkdir -p "$stub_dir"

  cat <<'SCRIPT' > "$stub_dir/free"
#!/bin/bash
echo "              total        used        free"
echo "Mem:             16            1           15"
SCRIPT
  chmod +x "$stub_dir/free"

  cat <<'SCRIPT' > "$stub_dir/df"
#!/bin/bash
echo "Filesystem     1G-blocks  Used Available Use% Mounted on"
echo "tmpfs                 0     0        100G  0% /"
SCRIPT
  chmod +x "$stub_dir/df"

  cat <<'SCRIPT' > "$stub_dir/vboxmanage"
#!/bin/bash
echo "7.0.10r158379"
SCRIPT
  chmod +x "$stub_dir/vboxmanage"

  cat <<'SCRIPT' > "$stub_dir/vagrant"
#!/bin/bash
echo "Vagrant 2.3.6"
SCRIPT
  chmod +x "$stub_dir/vagrant"

  cpuinfo="$stub_dir/cpuinfo"
  cat <<'CPU' > "$cpuinfo"
flags: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx lm constant_tsc rep_good nopl xtopology nonstop_tsc cpuid aperfmperf tsc_known_freq pni pclmulqdq vmx
CPU

  export VALIDATE_HOST_FREE_CMD="$stub_dir/free"
  export VALIDATE_HOST_DF_CMD="$stub_dir/df"
  export VALIDATE_HOST_VBOXMANAGE_CMD="$stub_dir/vboxmanage"
  export VALIDATE_HOST_VAGRANT_CMD="$stub_dir/vagrant"
  export VALIDATE_HOST_CPUINFO_FILE="$cpuinfo"

  run "$REPO_ROOT/bin/validate-host"

  [ "$status" -eq 0 ]
  [[ "$output" == *"[OK] All requirements met"* ]]
}

@test "validate-host: detecta error cuando no se puede leer la RAM" {
  stub_dir="$TMP_WORKDIR/stubs"
  mkdir -p "$stub_dir"

  cat <<'SCRIPT' > "$stub_dir/free"
#!/bin/bash
exit 0
SCRIPT
  chmod +x "$stub_dir/free"

  cat <<'SCRIPT' > "$stub_dir/df"
#!/bin/bash
echo "Filesystem     1G-blocks  Used Available Use% Mounted on"
echo "tmpfs                 0     0        100G  0% /"
SCRIPT
  chmod +x "$stub_dir/df"

  cat <<'SCRIPT' > "$stub_dir/vboxmanage"
#!/bin/bash
echo "7.0.10r158379"
SCRIPT
  chmod +x "$stub_dir/vboxmanage"

  cat <<'SCRIPT' > "$stub_dir/vagrant"
#!/bin/bash
echo "Vagrant 2.3.6"
SCRIPT
  chmod +x "$stub_dir/vagrant"

  cpuinfo="$stub_dir/cpuinfo"
  echo "flags : svm" > "$cpuinfo"

  export VALIDATE_HOST_FREE_CMD="$stub_dir/free"
  export VALIDATE_HOST_DF_CMD="$stub_dir/df"
  export VALIDATE_HOST_VBOXMANAGE_CMD="$stub_dir/vboxmanage"
  export VALIDATE_HOST_VAGRANT_CMD="$stub_dir/vagrant"
  export VALIDATE_HOST_CPUINFO_FILE="$cpuinfo"

  run "$REPO_ROOT/bin/validate-host"

  [ "$status" -eq 1 ]
  [[ "$output" == *"[ERROR] Cannot detect RAM"* ]]
  [[ "$output" == *"[ERROR] 1 requirement(s) not met"* ]]
}

@test "setup-project: modo dry-run no realiza cambios" {
  project_root="$TMP_WORKDIR/proyecto"
  export PROJECT_ROOT_OVERRIDE="$project_root"

  run "$REPO_ROOT/bin/setup-project" --dry-run

  [ "$status" -eq 0 ]
  [[ "$output" == *"[DRY-RUN] Creación de directorios"* ]]
  [[ "$output" == *"[DRY-RUN] Proyecto configurado"* ]]
  [ ! -d "$project_root" ]
}

@test "setup-project: crea estructura mínima" {
  project_root="$TMP_WORKDIR/proyecto"
  export PROJECT_ROOT_OVERRIDE="$project_root"
  export SETUP_PROJECT_SKIP_SECRETS=1

  run "$REPO_ROOT/bin/setup-project"

  [ "$status" -eq 0 ]
  [[ -d "$project_root/bin" ]]
  [[ -d "$project_root/docs" ]]
  [[ -f "$project_root/.gitignore" ]]
  grep -q "config/secrets.env" "$project_root/.gitignore"
  [[ "$output" == *"[OK] Project setup complete"* ]]
}

@test "install-apache: dry-run muestra pasos" {
  helper="$TMP_WORKDIR/helper.sh"
  cat <<'HELPER' > "$helper"
package_installed() { return 1; }
a2query() { return 1; }
apt-get() { echo "apt-get $*"; }
a2enmod() { echo "a2enmod $*"; }
systemctl() { echo "systemctl $*"; }
service_active() { return 0; }
port_listening() { return 0; }
command_exists() { return 0; }
apache2() { echo "Server version: Apache/2.4.58 (Unix)"; }
HELPER

  chmod +x "$helper"

  export INSTALL_APACHE_HELPERS="$helper"

  run "$REPO_ROOT/infrastructure/installation/install-apache.sh" --dry-run

  [ "$status" -eq 0 ]
  [[ "$output" == *"[DRY-RUN] Instalación de Apache completada"* ]]
}

@test "install-apache: propaga fallos de validación" {
  helper="$TMP_WORKDIR/helper_failure.sh"
  cat <<'HELPER' > "$helper"
check_root() { return 0; }
package_installed() { return 0; }
a2query() { return 0; }
apt-get() { return 0; }
a2enmod() { return 0; }
systemctl() { return 0; }
service_active() { return 1; }
port_listening() { return 1; }
command_exists() { return 1; }
apache2() { echo "Server version: Apache/2.4.58 (Unix)"; }
HELPER

  chmod +x "$helper"

  export INSTALL_APACHE_HELPERS="$helper"
  export APACHE_CONF_FILE="$TMP_WORKDIR/apache2.conf"
  touch "$APACHE_CONF_FILE"

  run "$REPO_ROOT/infrastructure/installation/install-apache.sh"

  [ "$status" -eq 1 ]
  [[ "$output" == *"Apache validation failed"* ]]
}
