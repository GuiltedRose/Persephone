#!/usr/bin/env bash
set -euo pipefail
binary=$1
shift
original=("$@")
# Inspect only known cracking options. Let upstream handle other modes,
# explicit wordlists, unknown options, and malformed invocations unchanged.
case "${1:-}" in
  --crack) shift ;;
  --seed|--embed|--extract|--info|--encinfo|--version|--license|--help|'')
    exec "$binary" "${original[@]}" ;;
esac
positionals=0
stegofile=0
while (( $# )); do
  case "$1" in
    -wl|--wordlist) exec "$binary" "${original[@]}" ;;
    -sf|--stegofile)
      (( $# >= 2 )) || exec "$binary" "${original[@]}"
      stegofile=1
      shift 2 ;;
    -xf|--extractfile|-t|--threads)
      (( $# >= 2 )) || exec "$binary" "${original[@]}"
      shift 2 ;;
    -v|--verbose|-q|--quiet|-f|--force|-s|--skipdefault|-a|--accessible|-n|--nocolor|-c|--continue|-K|--nochecksum)
      shift ;;
    -*) exec "$binary" "${original[@]}" ;;
    *) positionals=$((positionals + 1)); shift ;;
  esac
done
# Upstream assigns positional slot two to the wordlist even with -sf.
if (( positionals == 1 || (positionals == 0 && stegofile == 1) )); then
  exec "$binary" "${original[@]}" --wordlist "$PERSEPHONE_ROCKYOU"
fi
exec "$binary" "${original[@]}"
