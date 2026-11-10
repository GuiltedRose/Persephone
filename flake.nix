{
  description = "Persephone pentesting toolbox for Linux with the Nix package manager";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      eachSystem = nixpkgs.lib.genAttrs systems;
    in {
      packages = eachSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
          wordlists = pkgs.runCommand "persephone-wordlists" { } ''
            mkdir -p "$out"
            rockyou=$(find ${pkgs.rockyou}/share -type f -name rockyou.txt -print -quit)
            if test -n "$rockyou"; then
              ln -s "$rockyou" "$out/rockyou.txt"
            else
              rockyou=$(find ${pkgs.rockyou}/share -type f -name rockyou.txt.gz -print -quit)
              test -n "$rockyou"
              ${pkgs.gzip}/bin/gzip -dc "$rockyou" > "$out/rockyou.txt"
            fi
            ln -s ${pkgs.seclists}/share/wordlists/seclists "$out/seclists"
            ln -s "$out/seclists/Discovery/Web-Content/common.txt" "$out/web-common.txt"
            ln -s "$out/seclists/Discovery/DNS/subdomains-top1million-5000.txt" "$out/subdomains.txt"
            ln -s "$out/seclists/Usernames/top-usernames-shortlist.txt" "$out/usernames.txt"
            for list in rockyou.txt web-common.txt subdomains.txt usernames.txt; do
              test -s "$out/$list"
            done
          '';
          tools = with pkgs; [
            bashInteractive coreutils findutils gnugrep gnused gawk less jq
            curl wget openssl netcat-openbsd dnsutils whois
            nmap tcpdump tshark termshark ffuf gobuster sqlmap hydra john hashcat
            steghide exiftool file unzip p7zip openvpn
          ];
          # Supply the bundled list without relying on Kali's /usr/share paths.
          stegseek = pkgs.writeShellScriptBin "stegseek" ''
            export PERSEPHONE_ROCKYOU=${wordlists}/rockyou.txt
            exec ${pkgs.bash}/bin/bash ${./scripts/stegseek.sh} ${pkgs.stegseek}/bin/stegseek "$@"
          '';
          toolbox = pkgs.writeShellApplication {
            name = "persephone";
            runtimeInputs = [ stegseek ] ++ tools;
            text = ''
              export PERSEPHONE_WORDLISTS=${wordlists}
              export WORDLISTS="$PERSEPHONE_WORDLISTS"
              export ROCKYOU="$WORDLISTS/rockyou.txt"
              export PERSEPHONE_OPENVPN=${pkgs.openvpn}/bin/openvpn
              export PERSEPHONE_BASH=${pkgs.bashInteractive}/bin/bash
              export PERSEPHONE_TOOLS=${pkgs.lib.escapeShellArg (pkgs.lib.concatStringsSep " " ([ "stegseek" ] ++ map pkgs.lib.getName tools))}
              exec ${pkgs.bash}/bin/bash ${./scripts/persephone.sh} "$@"
            '';
          };
        in {
          default = toolbox;
          Persephone = toolbox;
          inherit toolbox wordlists;
        });
      apps = eachSystem (system: {
        default = self.apps.${system}.Persephone;
        Persephone = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/persephone";
        };
      });
    };
}
