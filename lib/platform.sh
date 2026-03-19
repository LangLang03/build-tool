#!/usr/bin/env bash

if [[ -z "${_BUILD_PLATFORM_LOADED:-}" ]]; then
_BUILD_PLATFORM_LOADED=1

declare -g PLATFORM_OS=""
declare -g PLATFORM_DISTRO=""
declare -g PLATFORM_DISTRO_FAMILY=""
declare -g PLATFORM_ARCH=""
declare -g PLATFORM_PACKAGE_MANAGER=""
declare -g PLATFORM_HAS_SUDO=false
declare -g PLATFORM_IS_WSL=false
declare -g PLATFORM_IS_GIT_BASH=false
declare -g PLATFORM_IS_CYGWIN=false
declare -g PLATFORM_IS_ROOT=false

declare -gA PACKAGE_MANAGERS=(
    ["apt"]="apt-get install -y"
    ["apt-get"]="apt-get install -y"
    ["dnf"]="dnf install -y"
    ["yum"]="yum install -y"
    ["pacman"]="pacman -S --noconfirm"
    ["zypper"]="zypper -n install"
    ["apk"]="apk add"
    ["emerge"]="emerge -v"
    ["brew"]="brew install"
    ["port"]="port install"
    ["choco"]="choco install -y"
    ["scoop"]="scoop install"
    ["winget"]="winget install --silent"
    ["pkg"]="pkg install -y"
    ["xbps"]="xbps-install -y"
    ["slackpkg"]="slackpkg install"
    ["nix"]="nix-env -i"
    ["snap"]="snap install"
    ["flatpak"]="flatpak install -y"
    ["guix"]="guix package -i"
    ["pkg_add"]="pkg_add"
    ["pkgin"]="pkgin install -y"
    ["eopkg"]="eopkg install -y"
    ["pacman-g2"]="pacman-g2 -S"
    ["scratch"]="scratch install"
    ["kiss"]="kiss build"
    ["cpt"]="cpt install"
    ["lpkg"]="lpkg -i"
    ["lpkgbuild"]="lpkgbuild"
    ["sorcery"]="cast"
    ["lumina"]="lumina install"
    ["butler"]="butler install"
)

declare -gA PACKAGE_UPDATE_COMMANDS=(
    ["apt"]="apt-get update"
    ["apt-get"]="apt-get update"
    ["dnf"]="dnf makecache"
    ["yum"]="yum makecache"
    ["pacman"]="pacman -Sy"
    ["zypper"]="zypper refresh"
    ["apk"]="apk update"
    ["emerge"]="emerge --sync"
    ["brew"]="brew update"
    ["port"]="port selfupdate"
    ["choco"]="choco upgrade chocolatey"
    ["scoop"]="scoop update"
    ["winget"]="winget source update"
    ["pkg"]="pkg update"
    ["xbps"]="xbps-install -S"
    ["slackpkg"]="slackpkg update"
    ["nix"]="nix-channel --update"
    ["snap"]="true"
    ["flatpak"]="flatpak update"
    ["guix"]="guix pull"
    ["pkg_add"]="pkg_add -u"
    ["pkgin"]="pkgin update"
    ["eopkg"]="eopkg update-repo"
    ["pacman-g2"]="pacman-g2 -Sy"
    ["scratch"]="scratch update"
    ["kiss"]="kiss update"
    ["cpt"]="cpt update"
    ["lpkg"]="lpkg -u"
    ["sorcery"]="scribe update"
    ["lumina"]="lumina update"
    ["butler"]="butler update"
)

declare -gA PACKAGE_SEARCH_COMMANDS=(
    ["apt"]="apt-cache search"
    ["apt-get"]="apt-cache search"
    ["dnf"]="dnf search"
    ["yum"]="yum search"
    ["pacman"]="pacman -Ss"
    ["zypper"]="zypper search"
    ["apk"]="apk search"
    ["emerge"]="emerge --search"
    ["brew"]="brew search"
    ["port"]="port search"
    ["choco"]="choco search"
    ["scoop"]="scoop search"
    ["winget"]="winget search"
    ["pkg"]="pkg search"
    ["xbps"]="xbps-query -Rs"
    ["slackpkg"]="slackpkg search"
    ["nix"]="nix search"
    ["snap"]="snap find"
    ["flatpak"]="flatpak search"
    ["guix"]="guix search"
    ["pkg_add"]="pkg_info -Q"
    ["pkgin"]="pkgin search"
    ["eopkg"]="eopkg search"
    ["pacman-g2"]="pacman-g2 -Ss"
    ["kiss"]="kiss search"
    ["cpt"]="cpt search"
)

declare -gA PACKAGE_REMOVE_COMMANDS=(
    ["apt"]="apt-get remove -y"
    ["apt-get"]="apt-get remove -y"
    ["dnf"]="dnf remove -y"
    ["yum"]="yum remove -y"
    ["pacman"]="pacman -R --noconfirm"
    ["zypper"]="zypper -n remove"
    ["apk"]="apk del"
    ["emerge"]="emerge -C"
    ["brew"]="brew uninstall"
    ["port"]="port uninstall"
    ["choco"]="choco uninstall -y"
    ["scoop"]="scoop uninstall"
    ["winget"]="winget uninstall --silent"
    ["pkg"]="pkg delete -y"
    ["xbps"]="xbps-remove -y"
    ["slackpkg"]="slackpkg remove"
    ["nix"]="nix-env -e"
    ["snap"]="snap remove"
    ["flatpak"]="flatpak uninstall -y"
    ["guix"]="guix package -r"
    ["pkg_add"]="pkg_delete"
    ["pkgin"]="pkgin remove"
    ["eopkg"]="eopkg remove"
    ["pacman-g2"]="pacman-g2 -R"
    ["kiss"]="kiss remove"
    ["cpt"]="cpt remove"
)

platform_detect() {
    PLATFORM_ARCH=$(uname -m)
    
    case "$PLATFORM_ARCH" in
        x86_64|amd64)
            PLATFORM_ARCH="x86_64"
            ;;
        aarch64|arm64)
            PLATFORM_ARCH="aarch64"
            ;;
        armv7l|armhf)
            PLATFORM_ARCH="armv7"
            ;;
        i386|i686)
            PLATFORM_ARCH="i386"
            ;;
    esac
    
    local os
    os=$(uname -s)
    
    case "$os" in
        Linux)
            PLATFORM_OS="linux"
            _platform_detect_linux_distro
            ;;
        Darwin)
            PLATFORM_OS="macos"
            PLATFORM_DISTRO="macos"
            PLATFORM_DISTRO_FAMILY="darwin"
            _platform_detect_macos_pm
            ;;
        CYGWIN*|MINGW*|MSYS*)
            PLATFORM_OS="windows"
            PLATFORM_DISTRO="windows"
            PLATFORM_DISTRO_FAMILY="windows"
            _platform_detect_windows_env "$os"
            ;;
        FreeBSD|OpenBSD|NetBSD)
            PLATFORM_OS="bsd"
            PLATFORM_DISTRO="${os,,}"
            PLATFORM_DISTRO_FAMILY="bsd"
            PLATFORM_PACKAGE_MANAGER="pkg_add"
            ;;
        SunOS)
            PLATFORM_OS="solaris"
            PLATFORM_DISTRO="solaris"
            PLATFORM_DISTRO_FAMILY="sunos"
            PLATFORM_PACKAGE_MANAGER="pkg"
            ;;
        *)
            PLATFORM_OS="${os,,}"
            PLATFORM_DISTRO="${os,,}"
            PLATFORM_DISTRO_FAMILY="unknown"
            ;;
    esac
    
    _platform_detect_sudo
    _platform_detect_root
}

_platform_detect_linux_distro() {
    local distro=""
    local family=""
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        distro="${ID:-unknown}"
        family="${ID_LIKE:-}"
    elif [[ -f /etc/redhat-release ]]; then
        distro="rhel"
        family="rhel"
    elif [[ -f /etc/debian_version ]]; then
        distro="debian"
        family="debian"
    elif [[ -f /etc/arch-release ]]; then
        distro="arch"
        family="arch"
    elif [[ -f /etc/gentoo-release ]]; then
        distro="gentoo"
        family="gentoo"
    elif [[ -f /etc/alpine-release ]]; then
        distro="alpine"
        family="alpine"
    elif [[ -f /etc/SuSE-release ]] || [[ -f /etc/sles-release ]]; then
        distro="suse"
        family="suse"
    elif [[ -f /etc/slackware-version ]]; then
        distro="slackware"
        family="slackware"
    elif [[ -f /etc/void-release ]]; then
        distro="void"
        family="void"
    elif [[ -f /etc/NIXOS ]]; then
        distro="nixos"
        family="nixos"
    elif [[ -f /etc/guix ]]; then
        distro="guix"
        family="guix"
    fi
    
    PLATFORM_DISTRO="${distro}"
    PLATFORM_DISTRO_FAMILY="${family}"
    
    _platform_detect_linux_pm
    _platform_detect_wsl
}

_platform_detect_linux_pm() {
    local managers=("apt" "apt-get" "dnf" "yum" "pacman" "zypper" "apk" "emerge" "xbps" "slackpkg" "nix" "snap" "flatpak" "guix" "eopkg" "pacman-g2" "kiss" "cpt" "sorcery")
    
    for pm in "${managers[@]}"; do
        if command -v "$pm" &>/dev/null; then
            PLATFORM_PACKAGE_MANAGER="$pm"
            return
        fi
    done
    
    PLATFORM_PACKAGE_MANAGER=""
}

_platform_detect_wsl() {
    if [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
        PLATFORM_IS_WSL=true
    else
        PLATFORM_IS_WSL=false
    fi
}

_platform_detect_macos_pm() {
    if command -v brew &>/dev/null; then
        PLATFORM_PACKAGE_MANAGER="brew"
    elif command -v port &>/dev/null; then
        PLATFORM_PACKAGE_MANAGER="port"
    else
        PLATFORM_PACKAGE_MANAGER=""
    fi
}

_platform_detect_windows_env() {
    local os="$1"
    
    case "$os" in
        CYGWIN*)
            PLATFORM_IS_CYGWIN=true
            ;;
        MINGW*|MSYS*)
            PLATFORM_IS_GIT_BASH=true
            ;;
    esac
    
    if command -v choco &>/dev/null; then
        PLATFORM_PACKAGE_MANAGER="choco"
    elif command -v scoop &>/dev/null; then
        PLATFORM_PACKAGE_MANAGER="scoop"
    elif command -v winget &>/dev/null; then
        PLATFORM_PACKAGE_MANAGER="winget"
    else
        PLATFORM_PACKAGE_MANAGER=""
    fi
}

_platform_detect_sudo() {
    if [[ $EUID -eq 0 ]]; then
        PLATFORM_HAS_SUDO=false
    elif command -v sudo &>/dev/null && sudo -n true 2>/dev/null; then
        PLATFORM_HAS_SUDO=true
    elif command -v sudo &>/dev/null; then
        PLATFORM_HAS_SUDO=true
    else
        PLATFORM_HAS_SUDO=false
    fi
}

_platform_detect_root() {
    if [[ $EUID -eq 0 ]]; then
        PLATFORM_IS_ROOT=true
    else
        PLATFORM_IS_ROOT=false
    fi
}

command_exists() {
    command -v "$1" &>/dev/null
}

require_command() {
    local cmd="$1"
    local message="${2:-$(i18n_get "command_required")}"
    
    if ! command_exists "$cmd"; then
        echo "$(i18n_get "error"): $message" >&2
        return 1
    fi
    return 0
}

require_commands() {
    local failed=()
    
    for cmd in "$@"; do
        if ! command_exists "$cmd"; then
            failed+=("$cmd")
        fi
    done
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        echo "$(i18n_get "error"): $(i18n_get "required_command_not_found")" >&2
        return 1
    fi
    return 0
}

platform_install() {
    local packages=("$@")
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        echo "$(i18n_get "error"): $(i18n_get "no_packages_specified")" >&2
        return 1
    fi
    
    if [[ -z "$PLATFORM_PACKAGE_MANAGER" ]]; then
        echo "$(i18n_get "error"): $(i18n_get "no_package_manager_detected")" >&2
        return 1
    fi
    
    local pm="$PLATFORM_PACKAGE_MANAGER"
    local install_cmd="${PACKAGE_MANAGERS[$pm]}"
    
    if [[ -z "$install_cmd" ]]; then
        echo "$(i18n_get "error"): $(i18n_get "unknown_package_manager"): $pm" >&2
        return 1
    fi
    
    local needs_sudo=false
    case "$pm" in
        apt|apt-get|dnf|yum|pacman|zypper|apk|emerge|brew|port|choco|scoop|winget|pkg|xbps|slackpkg|nix|snap|flatpak|guix)
            if [[ "$PLATFORM_IS_ROOT" != "true" ]]; then
                needs_sudo=true
            fi
            ;;
    esac
    
    local full_cmd=""
    if [[ "$needs_sudo" == "true" ]] && [[ "$PLATFORM_HAS_SUDO" == "true" ]]; then
        full_cmd="sudo $install_cmd ${packages[*]}"
    else
        full_cmd="$install_cmd ${packages[*]}"
    fi
    
    echo "$(i18n_get "installing_packages")"
    echo "$(i18n_get "using_package_manager")"
    echo "$(i18n_get "command")"
    
    eval "$full_cmd"
}

platform_update() {
    if [[ -z "$PLATFORM_PACKAGE_MANAGER" ]]; then
        echo "$(i18n_get "error"): $(i18n_get "no_package_manager_detected")" >&2
        return 1
    fi
    
    local pm="$PLATFORM_PACKAGE_MANAGER"
    local update_cmd="${PACKAGE_UPDATE_COMMANDS[$pm]}"
    
    if [[ -z "$update_cmd" ]]; then
        echo "$(i18n_get "error"): $(i18n_get "update_command_not_available")" >&2
        return 1
    fi
    
    local needs_sudo=false
    case "$pm" in
        apt|apt-get|dnf|yum|pacman|zypper|apk|emerge|xbps|slackpkg|eopkg|pacman-g2|kiss|cpt|sorcery)
            if [[ "$PLATFORM_IS_ROOT" != "true" ]]; then
                needs_sudo=true
            fi
            ;;
    esac
    
    local full_cmd=""
    if [[ "$needs_sudo" == "true" ]] && [[ "$PLATFORM_HAS_SUDO" == "true" ]]; then
        full_cmd="sudo $update_cmd"
    else
        full_cmd="$update_cmd"
    fi
    
    echo "$(i18n_get "updating_package_lists")"
    eval "$full_cmd"
}

platform_search() {
    local query="$1"
    
    if [[ -z "$query" ]]; then
        echo "$(i18n_get "error"): $(i18n_get "no_search_query")" >&2
        return 1
    fi
    
    if [[ -z "$PLATFORM_PACKAGE_MANAGER" ]]; then
        echo "$(i18n_get "error"): $(i18n_get "no_package_manager_detected")" >&2
        return 1
    fi
    
    local pm="$PLATFORM_PACKAGE_MANAGER"
    local search_cmd="${PACKAGE_SEARCH_COMMANDS[$pm]}"
    
    if [[ -z "$search_cmd" ]]; then
        echo "$(i18n_get "error"): $(i18n_get "search_command_not_available")" >&2
        return 1
    fi
    
    eval "$search_cmd $query"
}

platform_remove() {
    local packages=("$@")
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        echo "$(i18n_get "error"): $(i18n_get "no_packages_specified")" >&2
        return 1
    fi
    
    if [[ -z "$PLATFORM_PACKAGE_MANAGER" ]]; then
        echo "$(i18n_get "error"): $(i18n_get "no_package_manager_detected")" >&2
        return 1
    fi
    
    local pm="$PLATFORM_PACKAGE_MANAGER"
    local remove_cmd="${PACKAGE_REMOVE_COMMANDS[$pm]}"
    
    if [[ -z "$remove_cmd" ]]; then
        echo "$(i18n_get "error"): $(i18n_get "remove_command_not_available")" >&2
        return 1
    fi
    
    local needs_sudo=false
    case "$pm" in
        apt|apt-get|dnf|yum|pacman|zypper|apk|emerge|xbps|slackpkg|eopkg|pacman-g2|kiss|cpt|sorcery)
            if [[ "$PLATFORM_IS_ROOT" != "true" ]]; then
                needs_sudo=true
            fi
            ;;
    esac
    
    local full_cmd=""
    if [[ "$needs_sudo" == "true" ]] && [[ "$PLATFORM_HAS_SUDO" == "true" ]]; then
        full_cmd="sudo $remove_cmd ${packages[*]}"
    else
        full_cmd="$remove_cmd ${packages[*]}"
    fi
    
    echo "$(i18n_get "removing_packages")"
    eval "$full_cmd"
}

platform_get_info() {
    echo "$(i18n_get "platform_info")"
    echo "  $(i18n_get "os"):              $PLATFORM_OS"
    echo "  $(i18n_get "distribution"):    $PLATFORM_DISTRO"
    echo "  $(i18n_get "family"):          $PLATFORM_DISTRO_FAMILY"
    echo "  $(i18n_get "architecture"):    $PLATFORM_ARCH"
    echo "  $(i18n_get "package_manager"): ${PLATFORM_PACKAGE_MANAGER:-none}"
    echo "  $(i18n_get "has_sudo"):        $PLATFORM_HAS_SUDO"
    echo "  $(i18n_get "is_root"):         $PLATFORM_IS_ROOT"
    echo "  $(i18n_get "is_wsl"):          $PLATFORM_IS_WSL"
    echo "  $(i18n_get "is_git_bash"):     $PLATFORM_IS_GIT_BASH"
    echo "  $(i18n_get "is_cygwin"):       $PLATFORM_IS_CYGWIN"
}

platform_is_linux() {
    [[ "$PLATFORM_OS" == "linux" ]]
}

platform_is_macos() {
    [[ "$PLATFORM_OS" == "macos" ]]
}

platform_is_windows() {
    [[ "$PLATFORM_OS" == "windows" ]]
}

platform_is_bsd() {
    [[ "$PLATFORM_OS" == "bsd" ]]
}

platform_is_debian() {
    [[ "$PLATFORM_DISTRO_FAMILY" == *"debian"* ]] || [[ "$PLATFORM_DISTRO" == "debian" ]]
}

platform_is_redhat() {
    [[ "$PLATFORM_DISTRO_FAMILY" == *"rhel"* ]] || [[ "$PLATFORM_DISTRO_FAMILY" == *"fedora"* ]] || [[ "$PLATFORM_DISTRO" == "rhel" ]] || [[ "$PLATFORM_DISTRO" == "fedora" ]]
}

platform_is_arch() {
    [[ "$PLATFORM_DISTRO_FAMILY" == *"arch"* ]] || [[ "$PLATFORM_DISTRO" == "arch" ]]
}

platform_is_alpine() {
    [[ "$PLATFORM_DISTRO" == "alpine" ]]
}

platform_is_x86_64() {
    [[ "$PLATFORM_ARCH" == "x86_64" ]]
}

platform_is_arm() {
    [[ "$PLATFORM_ARCH" == "aarch64" ]] || [[ "$PLATFORM_ARCH" == "armv7" ]]
}

platform_run_sudo() {
    if [[ "$PLATFORM_IS_ROOT" == "true" ]]; then
        "$@"
    elif [[ "$PLATFORM_HAS_SUDO" == "true" ]]; then
        sudo "$@"
    else
        echo "$(i18n_get "error"): $(i18n_get "cannot_run_elevated")" >&2
        return 1
    fi
}

platform_path_to_native() {
    local path="$1"
    
    if [[ "$PLATFORM_IS_WSL" == "true" ]]; then
        wslpath -w "$path" 2>/dev/null || echo "$path"
    elif [[ "$PLATFORM_IS_GIT_BASH" == "true" ]] || [[ "$PLATFORM_IS_CYGWIN" == "true" ]]; then
        cygpath -w "$path" 2>/dev/null || echo "$path"
    else
        echo "$path"
    fi
}

platform_path_to_unix() {
    local path="$1"
    
    if [[ "$PLATFORM_IS_WSL" == "true" ]]; then
        wslpath -u "$path" 2>/dev/null || echo "$path"
    elif [[ "$PLATFORM_IS_GIT_BASH" == "true" ]] || [[ "$PLATFORM_IS_CYGWIN" == "true" ]]; then
        cygpath -u "$path" 2>/dev/null || echo "$path"
    else
        echo "$path"
    fi
}

platform_get_temp_dir() {
    if [[ "$PLATFORM_OS" == "windows" ]]; then
        echo "${TEMP:-/tmp}"
    else
        echo "${TMPDIR:-/tmp}"
    fi
}

platform_get_home_dir() {
    echo "${HOME:-$(cd ~ && pwd)}"
}

platform_get_config_dir() {
    if [[ "$PLATFORM_OS" == "macos" ]]; then
        echo "${HOME}/Library/Application Support"
    elif [[ "$PLATFORM_OS" == "windows" ]]; then
        echo "${APPDATA:-${HOME}/.config}"
    else
        echo "${XDG_CONFIG_HOME:-${HOME}/.config}"
    fi
}

platform_get_data_dir() {
    if [[ "$PLATFORM_OS" == "macos" ]]; then
        echo "${HOME}/Library/Application Support"
    elif [[ "$PLATFORM_OS" == "windows" ]]; then
        echo "${LOCALAPPDATA:-${HOME}/.local/share}"
    else
        echo "${XDG_DATA_HOME:-${HOME}/.local/share}"
    fi
}

platform_get_cache_dir() {
    if [[ "$PLATFORM_OS" == "macos" ]]; then
        echo "${HOME}/Library/Caches"
    elif [[ "$PLATFORM_OS" == "windows" ]]; then
        echo "${LOCALAPPDATA:-${HOME}/.cache}"
    else
        echo "${XDG_CACHE_HOME:-${HOME}/.cache}"
    fi
}

platform_detect

fi
