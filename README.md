# netbsd-base

NetBSD base environment setup — installs a full desktop stack via `pkgin`, configures `doas`, `i3`, `xinitrc`, and enables `dbus`.

## Contents

```
netbsd-base/
├── netbsd-base.ksh   # Main setup script (pure ksh)
├── pkgs              # Package list (365 packages)
├── doas/
│   └── doas.conf     # doas configuration (passwordless for wheel)
├── i3/
│   └── conf          # i3 window manager configuration
├── xinitrc/
│   └── .xinitrc      # X start-up script (starts i3)
└── README.md         # This file
```

## Requirements

- NetBSD (pkgsrc)
- `pkgin` installed and configured
- `ksh` (PD ksh v5.2.14 or compatible)
- The target user must exist and have a valid home directory
- The target user must be a member of the `wheel` group (required for `doas`)

## Usage

```sh
doas ./netbsd-base.ksh u="username"
```

**Single argument only:** `u="username"` specifies the target non-root user.

## What the script does

### 1. Package installation
Reads `pkgs` and installs every listed package via `pkgin install`. Packages already present on the system are detected and counted automatically. Skipped/failed packages are reported at the end.

### 2. doas configuration
- Installs the `doas` package.
- Copies `doas/doas.conf` to `/etc/doas.conf`.
- Sets permissions to `0400`.
- Backs up any existing configuration automatically.

The included `doas.conf` grants passwordless `doas` access to all members of the `wheel` group.

### 3. i3 configuration
- Creates `~/.config/i3/` if it does not exist.
- Copies `i3/conf` to `~/.config/i3/config`.
- Sets ownership to the target user.
- Backs up any existing configuration automatically.

### 4. .xinitrc
- Copies `xinitrc/.xinitrc` to `~/.xinitrc`.
- Sets ownership to the target user.
- Backs up any existing configuration automatically.

The included `.xinitrc` sets up XDG directories, disables screen blanking, starts `dunst` for notifications, sets the keyboard layout to Brazilian Portuguese (`setxkbmap br`), and launches `i3`.

### 5. dbus
- Adds or updates `dbus=yes` in `/etc/rc.conf`.

## Pre-run checklist

```
[ ] You are running NetBSD with pkgin configured
[ ] The target user exists and is not root
[ ] The target user has a valid home directory
[ ] The target user is in the wheel group
[ ] You have a working internet connection (packages are downloaded)
```

## After running

1. **Start dbus** (or reboot):
   ```sh
   doas /etc/rc.d/dbus start
   ```

2. **Log in as the target user** and start X:
   ```sh
   startx
   ```

3. **Use doas** (passwordless for wheel users):
   ```sh
   doas pkgin update
   doas shutdown -h now
   ```

## FAQ

**Q: Can I run this more than once?**
A: Yes. Existing configurations are backed up with a timestamp suffix before being replaced.

**Q: The script says a package failed. What do I do?**
A: Run `pkgin install <package>` manually as root to see the full error message. Common causes: network issues, package name changes in pkgsrc, or missing dependencies.

**Q: Can I add or remove packages from the `pkgs` file?**
A: Yes. Edit `pkgs` freely — one package name per line. Lines starting with `#` are comments and are ignored.

**Q: The target user is not in wheel. Can I still use doas?**
A: The `doas.conf` shipped here requires wheel membership. Edit `/etc/doas.conf` after installation to change the policy.

## Exit codes

| Code | Meaning |
|------|---------|
| `0`  | All steps completed successfully |
| `1`  | Error — check the error messages above |
