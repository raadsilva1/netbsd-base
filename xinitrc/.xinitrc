#!/bin/sh
# ~/.xinitrc — executed by startx / xinit

# ---------------------------------------------------------------------------
# 1. Environment
# ---------------------------------------------------------------------------
# Make sure XDG dirs exist (some WMs/DEs will silently misbehave otherwise).
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/xdg-runtime-$(id -u)}"
mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null && chmod 700 "$XDG_RUNTIME_DIR"

# Sane defaults if your shell profile didn't set them.
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="${EDITOR:-vi}"
export BROWSER="${BROWSER:-firefox}"
export TERMINAL="${TERMINAL:-xterm}"

# ---------------------------------------------------------------------------
# 2. X resources (xrdb)
# ---------------------------------------------------------------------------
# Load ~/.Xresources if present (colors, fonts, terminal settings, …).
[ -f "$HOME/.Xresources" ] && xrdb -merge -I"$HOME" "$HOME/.Xresources"

# ---------------------------------------------------------------------------
# 3. Look & feel
# ---------------------------------------------------------------------------
# Default cursor and root background.
# xsetroot -cursor_name left_ptr &
# If you use a wallpaper tool like feh, nitrogen, or hsetroot, call it here:
#   feh --bg-fill ~/Pictures/wallpaper.jpg &
#   nitrogen --restore &

# Disable screen blanking / DPMS if you want; comment out to keep defaults.
xset s off -dpms
xset b off

# NumLock on for the brave.
# numlockx &

# ---------------------------------------------------------------------------
# 4. Daemons (clipboard, compositor, polkit, notifications, …)
# ---------------------------------------------------------------------------
# Transparency / vsync
# picom -b &            # or: compton -b
# picom --config ~/.config/picom/picom.conf &

# Clipboard manager
# clipmenud &           # clipster / xclipboard / copyq

# Notifications
dunst &               # or: mako, twmnd, xfce4-notifyd

# Authentication agent (lets GUI apps prompt for sudo / mount / etc.)
# eval "$(ssh-agent)"
# exec start-pulseaudio-x11 &
# exec /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

# Network applet, volume applet, etc.
# nm-applet &
# volumeicon &

# Sync clipboard between X and Wayland apps (only useful in mixed setups)
# autocutsel -fork &
# autocutsel -fork -selection PRIMARY &

# ---------------------------------------------------------------------------
# 5. Keyboard / input
# ---------------------------------------------------------------------------
# Set a layout / variant (examples):
setxkbmap br 
#   setxkbmap de -variant nodeadkeys
#   setxkbmap -layout us,de -option grp:win_space_toggle
# CapsLock → Escape (vim users love this):
#   setxkbmap -option caps:escape

# Typing speed (debounce / repeat rate)
# xset r rate 250 35

# ---------------------------------------------------------------------------
# 6. Display / monitor configuration
# ---------------------------------------------------------------------------
# Single command for multi-monitor setup (replaces xrandr lines):
#   autorandr -c            # auto-load a saved profile
# Or hand-rolled:
#   xrandr --output HDMI-1 --mode 1920x1080 --rate 144 --primary \
#          --output eDP-1  --mode 1920x1080 --rate 60  --right-of HDMI-1

# HiDPI scaling for Qt/GTK apps (1.5x or 2x are common):
# export GDK_SCALE=2
# export GDK_DPI_SCALE=0.5
# export QT_SCALE_FACTOR=1.5
# export QT_AUTO_SCREEN_SCALE_FACTOR=1

# ---------------------------------------------------------------------------
# 7. Start the window manager / desktop environment
#    ↓↓↓ UNCOMMENT EXACTLY ONE ↓↓↓
# ---------------------------------------------------------------------------
# exec bspwm
exec i3
# exec sway                                 # Wayland, not really for startx
# exec awesome
# exec dwm
# exec xmonad
# exec herbstluftwm
# exec openbox-session
# exec xfce4-session
# exec mate-session
# exec cinnamon-session
# exec gnome-session
# exec kde-session                          # startkde, not always available
# exec icewm-session
# exec fluxbox
# exec jwm
# exec leftwm
# exec qtile start
# exec river                                # Wayland
# exec start-stumpwm
# exec /usr/bin/Xephyr :1 -ac -screen 1280x720 & sleep 1 ; DISPLAY=:1 awesome

# If you got here, nothing was selected — print a hint.
echo "xinitrc: no window manager selected. Edit ~/.xinitrc and uncomment one 'exec ...' line."
# exec xterm
