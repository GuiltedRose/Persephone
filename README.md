# Persephone

A single runnable pentesting toolbox for CachyOS/Arch using **only the Nix
package manager**. No NixOS modules, system configuration, services, or dev shell.

```sh
nix run .#Persephone
```

This opens an interactive Bash with every
included tool on PATH. Exit with `exit`. Your working directory and files remain
available; this is not a container. No tools or network scans start automatically.

Included: Nmap, tcpdump, tshark, ffuf, Gobuster, SQLMap, Hydra, John, Hashcat,
stegseek, steghide, ExifTool, OpenVPN, curl, wget, OpenSSL, netcat, DNS utilities,
whois, jq, file, unzip, 7-Zip, and basic shell utilities.

Bundled lists: RockYou, common web paths, common subdomains, short usernames,
and the full SecLists collection. First use downloads the tools and lists.

Inside the toolbox:

```sh
stegseek image.jpg                 # automatically uses bundled RockYou
steghide info image.jpg
ls "$WORDLISTS"
# Stable names: rockyou.txt, web-common.txt, subdomains.txt, usernames.txt
# Full collection: $WORDLISTS/seclists
sudo "$PERSEPHONE_OPENVPN" --config /absolute/path/to/htb.ovpn
```

Download your Hack The Box VPN configuration first. Use an absolute path; keep
VPN credentials outside this repository. OpenVPN runs in the foreground; Ctrl-C
disconnects it. Host sudo, a working /dev/net/tun, and host kernel TUN support are
required. The flake neither changes host networking nor grants privileges on
launch. OpenVPN applies the routes specified by your configuration when invoked.
Packet capture/raw sockets also require appropriate host permissions. GPU drivers
and OpenCL devices for Hashcat are provided by the host.

Direct invocation also works:

```sh
nix run .#Persephone -- --help
nix run .#Persephone -- nmap --version
nix run .#Persephone -- wordlists
```

## Operator setup and validation

Requires an installed, functioning Nix package manager on Linux. Enable
`experimental-features = nix-command flakes` in `~/.config/nix/nix.conf`
(merge with existing settings), or pass
`--extra-experimental-features 'nix-command flakes'` to each Nix command.

New files must be tracked for Git-backed flakes. Generate and retain the lock
before deployment; until then the input branch is not pinned:

```sh
git add flake.nix scripts README.md
nix flake lock
git add flake.lock
nix flake check --no-build
nix build .#Persephone
nix run .#Persephone -- nmap --version
nix run .#Persephone -- stegseek --help
nix run .#Persephone -- steghide --version
nix run .#Persephone -- openvpn --version
nix run .#Persephone -- bash -c 'for f in rockyou.txt web-common.txt subdomains.txt usernames.txt; do test -s "$WORDLISTS/$f" || exit 1; done'
nix run .#Persephone
```

No build, evaluation, test, VPN connection, or rollout was executed during
implementation. Package availability and wordlist layout must pass the above
validation on the operator's machine. No daemon activation is needed.

For upgrades, retain the previous flake files and lock in Git, then run
`nix flake update` and repeat validation before using the new revision. Roll back
by restoring `flake.nix`, `flake.lock`, and `scripts/` from that revision and
running `nix run .#Persephone`. Keep any running VPN in the foreground and stop
it with Ctrl-C before switching revisions. User data is never reset by this
flake. Use tools only against systems you are authorized to assess.
