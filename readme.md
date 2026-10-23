# Agentura

# Installation

Agent installations declared in Nix programming language. First of all you need to install nix
package manager & deployment system.
```sh
curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon && \
mkdir -p ~/.config/nix && \
echo 'experimental-features = nix-command flakes' >~/.config/nix/nix.conf && \
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

```sh
git clone git@github.com:stepan-dolgorukov/agentura.git
```

Two ways to install agents:

- devShell
```sh
nix develop ./agentura # to create shell with claude, grok, agy agents
nix develop ./agentura#$agent # agent ∈ {claude, grok, antigravity}
```
- nix profile
```sh
nix profile add ./agentura#claude
nix profile add ./agentura#grok
nix profile add ./agentura#antigravity
```
