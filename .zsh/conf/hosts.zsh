# SSH host shortcuts - zsh only. Tracked in git, so NO secrets, IPs or usernames here:
# connection details live in ~/.ssh/config (not in git). These just keep the old
# command names; `ssh porygon`, `scp x media:` etc. work directly too.
# Anything private goes in ssh.zsh instead (same folder, ignored by git).

## Raspberry Pi

# SSH into the media Pi
ssh_media () { ssh media "$@" }

# SSH into porygon
porygon () { ssh porygon "$@" }

# SSH into Home Assistant
ssh_hassio () { ssh hassio "$@" }

# SSH into the Pi-hole
ssh_pihole () { ssh pihole "$@" }

# SSH into ditto
ssh_ditto () { ssh ditto "$@" }

# SSH into rotom
ssh_rotom () { ssh rotom "$@" }

# SSH into jirachi
ssh_jirachi () { ssh jirachi "$@" }

## Web/Dev Servers

# SSH into the yow server
ssh_yow () { ssh yow "$@" }

# SSH into Flywheel (aimhigher-web)
ssh_flywheel () { ssh flywheel "$@" }

# SSH into the Strapi server
ssh_strapi () { ssh strapi "$@" }

## Other

# SSH into the reMarkable tablet
ssh_remarkable () { ssh remarkable "$@" }

# Copy *.svg and *.png in this folder to the reMarkable templates
copy_remarkable () {
	scp -v *.svg *.png remarkable:/usr/share/remarkable/templates/
}
