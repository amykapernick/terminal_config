# General utilities - zsh only.

# Generate font CSS from a fonts folder and copy it to the clipboard
# usage: gen_fonts [folder=src/fonts/]
gen_fonts () {
	python3 ~/functions/project_styles/gen_fonts.py --folder=${1:-src/fonts/}
	echo 'Fonts have been copied to the clipboard'
}

# Generate colour styles from pasted Sass variables (Ctrl-D to finish)
# usage: gen_colours [--gutenberg]
gen_colours () {
	python3 ~/functions/project_styles/gen_colours.py $1
}

# Delete all files with an extension under the current folder (asks first)
# usage: del_files <extension>
del_files () {
	find . -regex ".*\.$1$"
	read "response?Are you sure you want to delete these files? (y/n) "
	if [ "$response" = "y" ]
	then
		find . -regex ".*\.$1$" -delete
	fi
}

# Run npm start (if present), then npm run dev
start () {
	npm start --if-present
	npm run dev
}

# Free disk space: prune Docker, apt, npm, pip and brew caches, empty trash
cleanup () {
	docker system prune -af --volumes
	sudo apt clean && sudo apt autoremove -y
	npm cache clean --force
	pip3 cache purge
	brew cleanup -s && brew cleanup --prune=all
	empty_trash
}

# Permanently empty the rip trash
empty_trash () {
	rip --decompose
}

# SSH as <user>@<ip> using ~/.ssh/<key> (key defaults to the user name)
# usage: sssh <user> <ip> [key=<user>]
sssh () {
	name=$1
	ip=$2
	ssh_key=${3:-$name}

	ssh -i ~/.ssh/$ssh_key $name@$ip
}
