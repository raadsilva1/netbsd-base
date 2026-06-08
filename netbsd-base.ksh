#!/bin/ksh
#
# netbsd-base.ksh — NetBSD base environment setup
# Usage: netbsd-base.ksh u="target username"
#

set -eu

script_dir="${0%/*}"
if [[ "${0}" != */* ]]; then
    script_dir="."
fi
script_dir="$(cd -- "${script_dir}" && pwd)"

PKGS_FILE="${script_dir}/pkgs"
DOAS_CONF="${script_dir}/doas/doas.conf"
I3_CONF="${script_dir}/i3/conf"
XINITRC="${script_dir}/xinitrc/.xinitrc"

error() {
    printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2
}
warn() {
    printf '\033[1;33m[WARNING]\033[0m %s\n' "$*" >&2
}
info() {
    printf '\033[1;36m[INFO]\033[0m %s\n' "$*" >&2
}
ok() {
    printf '\033[1;32m[OK]\033[0m %s\n' "$*" >&2
}

validate_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        error "This script must be run with elevated permissions (root)."
        error "Hint: run with doas ./netbsd-base.ksh u=\"username\""
        exit 1
    fi
}

validate_args() {
    TARGET_USER=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            u=*)
                TARGET_USER="${1#u=}"
                ;;
            *)
                error "Unknown option: ${1}"
                error "Usage: ${0} u=\"username\""
                exit 1
                ;;
        esac
        shift
    done

    if [[ -z "${TARGET_USER}" ]]; then
        error "No target username provided."
        error "Usage: ${0} u=\"username\""
        exit 1
    fi

    if [[ "${TARGET_USER}" == "root" ]]; then
        error "The target user cannot be 'root'."
        exit 1
    fi

    if ! id "${TARGET_USER}" >/dev/null 2>&1; then
        error "User '${TARGET_USER}' does not exist on this system."
        exit 1
    fi

    USER_HOME=$(su - "${TARGET_USER}" -c 'printf "%s" ${HOME}' 2>/dev/null)
    if [[ -z "${USER_HOME}" ]]; then
        error "Could not determine home directory for user '${TARGET_USER}'."
        exit 1
    fi

    if [[ ! -d "${USER_HOME}" ]]; then
        error "Home directory '${USER_HOME}' for user '${TARGET_USER}' does not exist."
        exit 1
    fi

    TARGET_GROUP=$(id -gn "${TARGET_USER}" 2>/dev/null)
    if [[ -z "${TARGET_GROUP}" ]]; then
        error "Could not determine primary group for user '${TARGET_USER}'."
        exit 1
    fi
}

check_files() {
    local missing=0
    for file in "${PKGS_FILE}" "${DOAS_CONF}" "${I3_CONF}" "${XINITRC}"; do
        if [[ ! -f "${file}" ]]; then
            error "Required file not found: ${file}"
            missing=1
        fi
    done
    if [[ ${missing} -eq 1 ]]; then
        exit 1
    fi
}

install_packages() {
    info "Installing packages from: ${PKGS_FILE}"
    info "This may take a while. Please wait..."

    local pkg_count=0
    local pkg_fail=0
    local pkg_installed=0

    while IFS= read -r pkg || [[ -n "${pkg}" ]]; do
        pkg="${pkg#"${pkg%%[![:space:]]*}"}"
        pkg="${pkg%"${pkg##*[![:space:]]}"}"
        [[ -z "${pkg}" || "${pkg}" == \#* ]] && continue

        pkg_count=$((pkg_count + 1))
        printf '  Installing (%d): %s ... ' "${pkg_count}" "${pkg}"

        pkgin install "${pkg}" >/dev/null 2>&1
        rc=$?

        if [[ ${rc} -eq 0 ]]; then
            ok "${pkg}"
            pkg_installed=$((pkg_installed + 1))
        elif [[ ${rc} -eq 1 ]]; then
            found=0
            pkgin list 2>/dev/null >/tmp/.pkgin_list_${$}.tmp
            while IFS= read -r line; do
                case "${line}" in
                    "${pkg}-"*) found=1; break ;;
                esac
            done </tmp/.pkgin_list_${$}.tmp
            rm -f /tmp/.pkgin_list_${$}.tmp
            if [[ ${found} -eq 1 ]]; then
                ok "${pkg} (already installed)"
                pkg_installed=$((pkg_installed + 1))
            else
                warn "${pkg} — installation failed"
                pkg_fail=$((pkg_fail + 1))
            fi
        else
            warn "${pkg} — installation failed (exit ${rc})"
            pkg_fail=$((pkg_fail + 1))
        fi
    done < "${PKGS_FILE}"

    info "Package installation complete."
    info "  Installed / updated: ${pkg_installed}"
    if [[ ${pkg_fail} -gt 0 ]]; then
        warn "  Skipped / failed: ${pkg_fail}"
    fi
}

install_doas() {
    info "Installing doas..."
    if pkgin install doas >/dev/null 2>&1; then
        ok "doas installed successfully."
    else
        warn "doas package installation returned non-zero. Will attempt to copy config anyway."
    fi

    if [[ -f /etc/doas.conf ]]; then
        cp -f /etc/doas.conf /etc/doas.conf.bak.$(date +%Y%m%d%H%M%S) 2>/dev/null \
            && info "Existing /etc/doas.conf backed up." \
            || warn "Could not back up existing /etc/doas.conf."
    fi

    if cp -f "${DOAS_CONF}" /etc/doas.conf; then
        chmod 0400 /etc/doas.conf
        ok "doas configuration installed at /etc/doas.conf."
    else
        error "Failed to install doas configuration."
        exit 1
    fi
}

install_i3_config() {
    local i3_dest="${USER_HOME}/.config/i3/config"

    if mkdir -p "${USER_HOME}/.config/i3" 2>/dev/null; then
        ok "Directory ${USER_HOME}/.config/i3 created."
    else
        error "Failed to create ${USER_HOME}/.config/i3."
        exit 1
    fi

    if [[ -f "${i3_dest}" ]]; then
        cp -f "${i3_dest}" "${i3_dest}.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null \
            && info "Existing i3 config backed up." \
            || warn "Could not back up existing i3 config."
    fi

    if cp -f "${I3_CONF}" "${i3_dest}"; then
        chown "${TARGET_USER}:${TARGET_GROUP}" "${i3_dest}"
        ok "i3 configuration installed at ${i3_dest}."
    else
        error "Failed to install i3 configuration."
        exit 1
    fi
}

install_xinitrc() {
    local xinitrc_dest="${USER_HOME}/.xinitrc"

    if [[ -f "${xinitrc_dest}" ]]; then
        cp -f "${xinitrc_dest}" "${xinitrc_dest}.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null \
            && info "Existing ${xinitrc_dest} backed up." \
            || warn "Could not back up existing .xinitrc."
    fi

    if cp -f "${XINITRC}" "${xinitrc_dest}"; then
        chown "${TARGET_USER}:${TARGET_GROUP}" "${xinitrc_dest}"
        ok ".xinitrc installed at ${xinitrc_dest}."
    else
        error "Failed to install .xinitrc."
        exit 1
    fi
}

enable_dbus() {
    info "Enabling dbus in /etc/rc.conf..."

    if grep -q '^dbus=' /etc/rc.conf 2>/dev/null; then
        if sed -i 's/^dbus=.*/dbus=yes/' /etc/rc.conf; then
            ok "dbus enabled in /etc/rc.conf (updated existing entry)."
        else
            error "Failed to update dbus entry in /etc/rc.conf."
            exit 1
        fi
    else
        if printf '\ndbus=yes\n' >> /etc/rc.conf; then
            ok "dbus enabled in /etc/rc.conf (new entry added)."
        else
            error "Failed to add dbus entry to /etc/rc.conf."
            exit 1
        fi
    fi
}

print_summary() {
    printf '\n'
    printf '=============================================================\n'
    printf '               NETBSD BASE SETUP — SUMMARY\n'
    printf '=============================================================\n'
    printf '\n'
    printf '  Target user : %s\n' "${TARGET_USER}"
    printf '  User home   : %s\n' "${USER_HOME}"
    printf '\n'
    printf '  Package list : %s\n' "${PKGS_FILE}"
    printf '  Packages     : installed from pkgs file\n'
    printf '\n'
    printf '  doas configuration : /etc/doas.conf\n'
    printf '  i3 configuration   : %s/.config/i3/config\n' "${USER_HOME}"
    printf '  .xinitrc           : %s/.xinitrc\n' "${USER_HOME}"
    printf '  dbus               : enabled in /etc/rc.conf\n'
    printf '\n'
    printf '=============================================================\n'
    printf '  Setup completed successfully!\n'
    printf '\n'
    printf '  Next steps:\n'
    printf '  1. Reboot or start dbus manually:\n'
    printf '       doas /etc/rc.d/dbus start\n'
    printf '\n'
    printf '  2. Log in as %s and run:\n' "${TARGET_USER}"
    printf '       startx\n'
    printf '\n'
    printf '  3. To use doas (passwordless for wheel users):\n'
    printf '       doas <command>\n'
    printf '\n'
    printf '=============================================================\n'
}

main() {
    validate_root
    validate_args "${@}"
    check_files

    printf '\n'
    printf '=============================================================\n'
    printf '               NETBSD BASE SETUP — STARTING\n'
    printf '=============================================================\n'
    printf '\n'

    install_packages
    install_doas
    install_i3_config
    install_xinitrc
    enable_dbus

    print_summary
}

main ${1+"${@}"}
