# AimHigher mode: sourced by ~/.local/bin/mode. Plain bash.

LABEL="AimHigher"
# Shown as the workspace name instead of LABEL (saves top-bar space).
ICON="💼"

# 1-based workspace the apps are moved to (needs the Modes extension).
# Leave empty to open apps wherever you are.
WORKSPACE=2

# .desktop ids. Find them with: ls /usr/share/applications /var/lib/flatpak/exports/share/applications /var/lib/snapd/desktop/applications
# Apps that were already running when the mode started are left running on end
# (their windows on this workspace are still closed).
APPS=(
	com.mitchellh.ghostty.desktop # terminal
	firefox_firefox.desktop       # snap
)

# Apps whose existing windows are moved here too, and moved back on pause/end.
BRING=(com.slack.Slack.desktop)

# "schema key value" (the value uses gsettings syntax). Saved on start, restored on pause/end.
SETTINGS=(
	"org.gnome.desktop.notifications show-banners false"
	"org.gnome.desktop.break-reminders selected-breaks ['eyesight', 'movement']"
	# "org.gnome.settings-daemon.plugins.color night-light-enabled true"
	# "org.gnome.desktop.background picture-uri-dark 'file:///home/amy/Pictures/work.png'"
)

# Default web browser while the mode is on (a .desktop id); the previous one is restored on pause/end.
BROWSER=firefox_firefox.desktop

# Optional: override how an app is detected/closed (a pgrep -f regex).
# KILL_MATCH[some.app.desktop]='^/opt/some/app( |$)'

# Optional hooks, run after settings are applied / before apps are closed.
# on_start() { :; }
# on_stop()  { :; }

# Open the terminal in ~/web (a separate Ghostty process, so it gets its own folder).
LAUNCH[com.mitchellh.ghostty.desktop]="ghostty --gtk-single-instance=false --working-directory=$HOME/web"

# Where windows go: monitor=left|centre|right|<n>|primary|<connector, e.g. DP-3>,
# then "maximize", or x= y= w= h= as % of the monitor (or px).
# PLACE[com.mitchellh.ghostty.desktop]='monitor=left maximize'
# PLACE[com.slack.Slack.desktop]='monitor=right x=0 y=0 w=50% h=100%'

# Start TIDAL Hi-Fi with this mode and play; pauses on pause/end/switch.
MUSIC=1
