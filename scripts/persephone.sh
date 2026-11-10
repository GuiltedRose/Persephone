#!/usr/bin/env bash
set -euo pipefail
case "${1:-shell}" in
  -h|--help|help)
    cat <<'HELP'
Persephone: nix run .#Persephone -- [command [arguments...]]
  shell              Interactive toolbox (also the default)
  tools              List included packages
  wordlists          Print the bundled wordlist directory
  vpn FILE [OPTIONS] Run OpenVPN with an absolute config path (requires root)
  COMMAND [ARGS]     Run a tool, for example nmap --version

Inside the toolbox: $WORDLISTS, $ROCKYOU, $PERSEPHONE_OPENVPN
stegseek defaults to the bundled RockYou list in cracking mode.
HELP
    ;;
  tools)
    read -r -a tools <<< "$PERSEPHONE_TOOLS"
    printf '%s\n' "${tools[@]}"
    ;;
  wordlists) printf '%s\n' "$WORDLISTS" ;;
  shell)
    shift "$(( $# > 0 ? 1 : 0 ))"
    exec "$PERSEPHONE_BASH" --noprofile --norc -i "$@"
    ;;
  vpn)
    shift
    if [[ $# -eq 0 || $1 != /* || ! -r $1 ]]; then
      printf 'Usage: nix run .#Persephone -- vpn /absolute/path/to/htb.ovpn [options]\n' >&2
      exit 2
    fi
    if (( EUID != 0 )); then
      printf 'OpenVPN needs root. From the toolbox run: sudo "$PERSEPHONE_OPENVPN" --config /absolute/path/to/htb.ovpn\n' >&2
      exit 1
    fi
    config=$1
    shift
    exec "$PERSEPHONE_OPENVPN" --config "$config" "$@"
    ;;
  *) exec "$@" ;;
esac
