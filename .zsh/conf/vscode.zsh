# VS Code profile → folders (relative to ~, space separated); most specific path wins
typeset -gA VSCODE_PROFILES=(
	Presentations "training/workshops training/demos"
	MakerX "makerx"
)

# Open folders with a VS Code profile based on where they live
# usage: code [vscode args...] [folder=.]
code () {
	local target="${@[-1]:-.}"
	[[ "$target" == -* ]] && target="."
	local abs="${target:A}" profile="" best="" name dir

	for name in "${(@k)VSCODE_PROFILES}"
	do
		for dir in ${(s: :)VSCODE_PROFILES[$name]}
		do
			dir="$HOME/$dir"
			if [[ ( "$abs" == "$dir" || "$abs" == "$dir/"* ) && ${#dir} -gt ${#best} ]]
			then
				best="$dir"
				profile="$name"
			fi
		done
	done

	if [[ -n "$profile" && "$*" != *--profile* ]]
	then
		command code --profile "$profile" "$@"
	else
		command code "$@"
	fi
}
