# MakerX mode: links open in Chrome with the MakerX profile.
LABEL="MakerX"
# Shown as the workspace name instead of LABEL (saves top-bar space).
ICON="🤖"
BROWSER=chrome-makerx.desktop
WORKSPACE=3

# Opened when the mode starts; new windows go to workspace 3.
APPS=(
	chrome-makerx.desktop
	com.mitchellh.ghostty.desktop
	roam.desktop
)

# Existing windows are moved to workspace 3 too, and moved back on stop.
BRING=(
	com.slack.Slack.desktop
)

# google-chrome-stable is a wrapper script; the real process is .../chrome.
KILL_MATCH[chrome-makerx.desktop]='^/opt/google/chrome/chrome( |$)'

# Wellbeing break reminders while the mode is on (restored on pause/end).
# While a break is due, the Modes extension pauses any playing music.
SETTINGS=(
	"org.gnome.desktop.break-reminders selected-breaks ['eyesight', 'movement']"
)

# Open the terminal in ~/makerx (a separate Ghostty process, so it gets its own folder).
LAUNCH[com.mitchellh.ghostty.desktop]="ghostty --gtk-single-instance=false --working-directory=$HOME/makerx"

# Where windows go: monitor=left|centre|right|<n>|primary|<connector, e.g. DP-3>,
# then "maximize", or x= y= w= h= as % of the monitor (or px).
# PLACE[com.mitchellh.ghostty.desktop]='monitor=left maximize'
# PLACE[com.slack.Slack.desktop]='monitor=right x=0 y=0 w=50% h=100%'

# Start TIDAL Hi-Fi with this mode and play; pauses on pause/end/switch.
MUSIC=1
