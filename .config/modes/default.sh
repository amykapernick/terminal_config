# Default: the normal state. It's on whenever no other mode is.
# Choosing it pauses the current mode and takes you to workspace 1.
# At login (see autostart/modes-default.desktop) it sets up the workspaces and
# opens APPS. Background/tray apps (1Password, Slack, Discord...) stay in
# ~/.config/autostart because they need their own start-up flags.
LABEL="Default"
# Shown as the workspace name instead of LABEL (saves top-bar space).
ICON="👩‍💻"
WORKSPACE=1

# Links open in Edge with the personal profile (its email: `git config email.personal`).
BROWSER=edge-kapers.desktop

# Extra apps to open at login (only if not already running).
APPS=()

# Where windows go: monitor=left|centre|right|<n>|primary|<connector, e.g. DP-3>,
# then "maximize", or x= y= w= h= as % of the monitor (or px). Applies to
# windows that open in the 30 s after Default starts (e.g. at login).
# PLACE[com.slack.Slack.desktop]='monitor=left x=0 y=0 w=50% h=100%'
# PLACE[com.discordapp.Discord.desktop]='monitor=left x=50% y=0 w=50% h=100%'

# Settings to (re)apply when going back to Default. Not saved/restored.
# Break reminders are off outside work modes.
SETTINGS=(
	"org.gnome.desktop.break-reminders selected-breaks @as []"
)
