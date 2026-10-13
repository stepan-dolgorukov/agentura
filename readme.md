# Agentura

# Installation

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
