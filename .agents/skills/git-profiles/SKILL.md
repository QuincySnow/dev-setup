---
name: git-profiles
description: Manage multiple Git identities (work, personal, etc.) based on repository directory. Automatically switches identity before git push operations.
---

# Git Profiles

## Overview

Automatically switch Git identities based on repository directory using Git's conditional includes. Before any push operation, ensure the correct identity is set.

## Configuration

### Main ~/.gitconfig

```gitconfig
[includeIf "gitdir:~/work/"]
    path = ~/.gitconfig-work

[includeIf "gitdir:~/personal/"]
    path = ~/.gitconfig-personal
```

### Profile ~/.gitconfig-work

```gitconfig
[user]
    name = Your Work Name
    email = you@example.com
```

### Profile ~/.gitconfig-personal

```gitconfig
[user]
    name = Your Personal Name
    email = personal@example.com
```

## Usage

Place repositories in their respective directories:
- `~/work/` → uses work identity
- `~/personal/` → uses personal identity
- Other directories → uses default identity

## Auto Switch Before Push

Before running `git push`, always automatically set the correct identity based on the repository directory:

```bash
# Detect current repo path and set appropriate identity
REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"

if [[ "$REPO_DIR" == ~/Work/* ]]; then
    git config user.name "SKIPPINGpetticoatconvent"
    git config user.email "146918156+SKIPPINGpetticoatconvent@users.noreply.github.com"
elif [[ "$REPO_DIR" == ~/Dark/* ]]; then
    git config user.name "youugiuhiuh"
    git config user.email "260548057+youugiuhiuh@users.noreply.github.com"
fi
```

## Show Current Profile

```bash
git profile
```

This alias shows current user settings and remotes.

## Scripts

- `show-profile.sh`: Display current Git identity
