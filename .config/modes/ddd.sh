# DDD Perth mode: links open in Edge with the DDD Perth profile (its email: `git config email.ddd`).
LABEL="DDD Perth"
# Shown as the workspace name instead of LABEL (saves top-bar space).
ICON="🎤"
BROWSER=edge-ddd.desktop
WORKSPACE=4

# Opened when the mode starts; new windows go to workspace 4.
APPS=(
	edge-ddd.desktop
)

# Existing windows are moved to workspace 4 too, and moved back on pause/end.
# Discord starts at login, so it's moved rather than opened and closed.
BRING=(
	com.discordapp.Discord.desktop
)

# microsoft-edge-stable is a wrapper script; the real process is .../msedge.
KILL_MATCH[edge-ddd.desktop]='^/opt/microsoft/msedge/msedge( |$)'

# Wellbeing break reminders while the mode is on (restored on pause/end).
# While a break is due, the Modes extension pauses any playing music.
SETTINGS=(
	"org.gnome.desktop.break-reminders selected-breaks ['eyesight', 'movement']"
)

# Start TIDAL Hi-Fi with this mode and play; pauses on pause/end/switch.
# MUSIC=1
