# SSH Key Setup and Connection to GitHub

> Part of the initial Arch Linux setup after installing base packages. Goal — generate an SSH key, link it to a GitHub account, and configure git for commits with a private email.

[![Russian](https://img.shields.io/badge/lang-Russian-lightgrey)](Setting_SSH_key.md) ![English](https://img.shields.io/badge/lang-English-1793d1)

---

## 📋 Table of Contents

- [Prerequisites](#-prerequisites)
- [1. Check Existing Keys](#1-check-existing-keys)
- [2. Key Generation](#2-key-generation)
- [3. View the Public Key](#3-view-the-public-key)
- [4. Add the Key to GitHub](#4-add-the-key-to-github)
- [5. Connection Test](#5-connection-test)
- [6. git Setup: Name](#6-git-setup-name)
- [7. git Setup: Email via no-reply](#7-git-setup-email-via-no-reply)
- [8. Verify the Result](#8-verify-the-result)

---

## 📌 Prerequisites

- `git` installed — included in the base pacstrap set (see [Arch Linux Installation → Step 4](Arch_linux_install.en.md#4-base-system-installation))
- Have a GitHub account
- Active network connection

---

## 1. Check Existing Keys

```bash
ls -la ~/.ssh/ 2>/dev/null
```

- If the folder is **empty or doesn't exist** — proceed to [generation](#2-key-generation).
- If it already contains `id_ed25519` / `id_rsa` — you can use the existing key (copy its public part `*.pub` directly to [step 3](#3-view-the-public-key)).

---

## 2. Key Generation

We use the **`ed25519`** algorithm — modern, faster and safer than RSA, with short keys.

```bash
ssh-keygen -t ed25519 -C "your_comment"
```

### Flags

| Flag | Purpose |
|---|---|
| `-t ed25519` | Key type |
| `-C "..."` | Comment — a label to identify the key in the GitHub list. Doesn't affect security. Convenient to use `user@machine`. |

### Interactive prompts

| Prompt | Answer |
|---|---|
| `Enter file in which to save the key` | **Enter** (default: `~/.ssh/id_ed25519`) |
| `Enter passphrase` | **Enter** (empty) or enter a password |

> 💡 **Passphrase or not?**
> - **Empty** — key works without password input, convenient for a personal machine.
> - **With passphrase** — asks for password every time (or once per session via `ssh-agent`).

### Result

After generation, two files will appear:

| File | What it is |
|---|---|
| `~/.ssh/id_ed25519` | 🔒 **Private key** — don't show, don't commit, don't publish |
| `~/.ssh/id_ed25519.pub` | 🌐 **Public key** — give to GitHub |

---

## 3. View the Public Key

```bash
cat ~/.ssh/id_ed25519.pub
```

Output — a single line like:

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE... your_comment
```

**Copy it in full** — from `ssh-ed25519` up to and including the comment.

---

## 4. Add the Key to GitHub

1. Open [github.com/settings/keys](https://github.com/settings/keys)
2. Click **New SSH key** (green button in the upper right corner)
3. Fill in the fields:

| Field | Value |
|---|---|
| **Title** | Identification label, e.g. `ArchLinux laptop` |
| **Key type** | `Authentication Key` (leave as default) |
| **Key** | Paste the full line from [step 3](#3-view-the-public-key) |

4. Click **Add SSH key** (may ask for account password)

---

## 5. Connection Test

```bash
ssh -T git@github.com
```

First run will ask:

```
The authenticity of host 'github.com (...)' can't be established.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Answer `yes`. GitHub's fingerprint is written to `~/.ssh/known_hosts`, won't ask again.

### Expected successful response

```
Hi <username>! You've successfully authenticated, but GitHub does not provide shell access.
```

> 💡 The line `does not provide shell access` is **not an error**. GitHub doesn't provide shell access, only git operations (push / pull / clone, etc.).

---

## 6. git Setup: Name

Name and email are written into every commit.

```bash
git config --global user.name "Name"
```

> 💡 Can be real name, nickname, anything — visible in the commit history.

---

## 7. git Setup: Email via no-reply

> ⚠️ **Don't use a real email in public commits.**
>
> The email from `git config` ends up in every commit and is visible in public repos **forever**. GitHub provides a private no-reply address linked to the account but not revealing the real email.

### Getting the no-reply address

1. Open [github.com/settings/emails](https://github.com/settings/emails)
2. Enable **Keep my email addresses private**
3. Copy the line like `12345678+github@users.noreply.github.com`

> 💡 The numeric prefix is unique to each user.

### Setting the email

```bash
git config --global user.email "12345678+github@users.noreply.github.com"
```

---

## 8. Verify the Result

```bash
git config --global --list | grep user
```

### Expected output

```
user.name=your_name
user.email=12345678+github@users.noreply.github.com
```

---

## ✅ Done

SSH key configured, git linked to GitHub via a private email. Now you can clone repositories via SSH:

```bash
git clone git@github.com:<username>/<repo>.git
```

> 🎉 **Ready to work with private repos and push to public ones.**
