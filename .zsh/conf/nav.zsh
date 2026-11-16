# Folder navigation - zsh only. (wp lives in wsl.zsh: it needs the ~/windows link)

# cd to ~/<folder>, then into <subfolder> or list its contents
# usage: move_folder <folder> [subfolder]
move_folder () {
	cd ~/$1
	if [ -n "$2" ]
	then
		cd $2
	else
		ls -la
	fi
}

# Go to ~/web, or a project inside it
# usage: web [project]
web () {
	# cd ~/web
	# if [ -n "$1" ]
	# then
	# 	cd $1
	# fi
	move_folder "web" $1
}

# Go to ~/dev, or a project inside it
# usage: dev [project]
dev () {
	move_folder "dev" $1
}

# Go to ~/training, or a folder inside it
# usage: train [folder]
train () {
	move_folder "training" $1
}

# Go to ~/makerx, or a project inside it
# usage: makerx [project]
makerx () {
	move_folder "makerx" $1
}
