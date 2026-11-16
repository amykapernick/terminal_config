# Help / lookup for the functions and aliases in ~/.zsh/conf/*.zsh - zsh only
#
# Document a function with comment lines directly above it:
#   # Short description of what it does
#   # usage: name <required> [optional=default]
# Without a usage line, the arguments are guessed from $1, ${2:-default}, name=$1 etc.
#
#   fhelp            fuzzy-search everything (Enter puts the command on your prompt)
#   fhelp <words>    search pre-filled with <words>, or full help if it's an exact name
#   Ctrl+G           same picker from the prompt, using what you've typed as the search
#   while typing     matching functions/usage are shown under the prompt
#   Tab              after a function name, shows its usage above the completions

zmodload zsh/parameter 2>/dev/null
typeset -gA _BF_USAGE _BF_DESC _BF_LOC
typeset -g _BF_LIST

_bf_index () {
	_BF_USAGE=() _BF_DESC=() _BF_LOC=()
	_BF_LIST=""
	local -a files=(~/.zsh/conf/*.zsh(N.))
	files=(${files:#*/help.zsh})

	local name usage desc file start end
	while IFS=$'\x1f' read -r name usage desc file start end
	do
		[[ $name == _* ]] && continue
		if [[ $usage == alias ]]
		then
			(( $+aliases[$name] )) || continue
			usage=$name
		else
			# skip functions that aren't loaded, or that were redefined in a later file
			(( $+functions[$name] )) || continue
			[[ ${functions_source[$name]:A} == ${file:A} ]] || continue
		fi
		_BF_USAGE[$name]=$usage
		_BF_DESC[$name]=$desc
		_BF_LOC[$name]="$file:$start"
		_BF_LIST+="$name"$'\t'"${(r:40:)usage} "$'\t'"$desc"$'\t'"$file"$'\t'"$start"$'\t'"$end"$'\n'
	done < <(awk -f - "${files[@]}" <<'AWK'
BEGIN { SEP = "\037" }
function reset_comments() { cdesc = ""; cusage = ""; cstart = 0 }
function scan(s,   t, rest, n, d, v, pre) {
	if (s ~ /\$\{?[@*]/) varargs = 1
	t = s
	while (match(t, /\$\{?[1-9]/)) {
		pre = substr(t, 1, RSTART - 1); rest = substr(t, RSTART)
		braced = (substr(rest, 2, 1) == "{")
		n = substr(rest, braced ? 3 : 2, 1) + 0
		if (n > maxarg) maxarg = n
		if (braced && substr(rest, 4, 2) == ":-" && !(n in argdef)) {
			d = substr(rest, 6); sub(/\}.*/, "", d); argdef[n] = d
		}
		if (pre ~ /[A-Za-z_][A-Za-z0-9_]*="?$/ && !(n in argname)) {
			v = pre; sub(/="?$/, "", v); sub(/.*[^A-Za-z0-9_]/, "", v); argname[n] = v
		}
		t = substr(rest, 2)
	}
}
function emit(   u, i, a) {
	u = usage
	if (u == "") {
		u = name
		for (i = 1; i <= maxarg; i++) {
			a = (i in argname) ? argname[i] : "arg" i
			u = u ((i in argdef) ? " [" a "=" argdef[i] "]" : " <" a ">")
		}
		if (varargs) u = u " [args...]"
	} else if (index(u, name) != 1) u = name " " u
	print name SEP u SEP desc SEP FILENAME SEP start SEP FNR
	infn = 0
}
FNR == 1 { infn = 0; reset_comments() }
infn && /^\}/ { emit(); next }
infn { if ($0 !~ /^[ \t]*#/) scan($0); next }
/^[ \t]*#/ {
	line = $0; sub(/^[ \t]*#+[ \t]?/, "", line)
	if (line ~ /^alias /) { reset_comments(); next }   # commented-out alias
	if (cstart == 0) cstart = FNR
	if (line ~ /^usage:/) { sub(/^usage:[ \t]*/, "", line); cusage = line }
	else if (line != "") cdesc = (cdesc == "" ? line : cdesc " " line)
	next
}
/^[A-Za-z_][A-Za-z0-9_-]*[ \t]*\(\)/ {
	name = $0; sub(/[ \t]*\(\).*/, "", name)
	start = cstart ? cstart : FNR
	desc = cdesc; usage = cusage; reset_comments()
	infn = 1; maxarg = 0; varargs = 0
	delete argname; delete argdef
	body = $0; sub(/^[^{]*\{?/, "", body)
	if (body ~ /\}[ \t]*$/) { scan(body); emit() }   # one-line function
	next
}
/^alias / {
	line = $0; sub(/^alias[ \t]+/, "", line)
	n = line; sub(/=.*/, "", n)
	v = line; sub(/^[^=]*=/, "", v); gsub(/^["']|["'][ \t]*(#.*)?$/, "", v)
	d = (cdesc != "") ? cdesc : "alias for: " v
	print n SEP "alias" SEP d SEP FILENAME SEP (cstart ? cstart : FNR) SEP FNR
	reset_comments(); next
}
{ reset_comments() }
AWK
	)
}

_bf_pick () {
	print -rn -- "$_BF_LIST" | fzf \
		--delimiter=$'\t' --with-nth=2,3 --query="$1" \
		--height=60% --layout=reverse --border --info=inline \
		--prompt='function> ' --header='Enter: put on prompt   Esc: cancel' \
		--preview-window='down,60%,wrap' \
		--preview='printf "\033[1;33m%s\033[0m\n%s\n\033[2m%s:%s\033[0m\n\n" "$(echo {2} | sed "s/ *\$//")" {3} {4} {5}; bat --color=always --style=numbers --line-range={5}:{6} {4} 2>/dev/null || sed -n "{5},{6}p" {4}' \
		| cut -f1
}

fhelp () {
	if [[ $# -eq 1 && -n ${_BF_USAGE[$1]} ]]
	then
		print -P "%B%F{yellow}${_BF_USAGE[$1]//\%/%%}%f%b"
		[[ -n ${_BF_DESC[$1]} ]] && print -r -- "${_BF_DESC[$1]}"
		print -P "%F{8}${_BF_LOC[$1]/#$HOME/~}%f"
		return
	fi
	local pick=$(_bf_pick "$*")
	[[ -n $pick ]] && print -z -- "$pick "
}

# Ctrl+G: picker from the prompt
_bf_widget () {
	local -a w=(${(z)LBUFFER})
	local pick=$(_bf_pick "${w[1]}")
	zle reset-prompt
	if [[ -n $pick ]]
	then
		BUFFER="$pick "
		CURSOR=$#BUFFER
		zle -M "${_BF_USAGE[$pick]}${_BF_DESC[$pick]:+  —  ${_BF_DESC[$pick]}}"
	fi
}
zle -N _bf_widget
bindkey '^G' _bf_widget

# Live hints under the prompt while typing
typeset -g _BF_LAST_HINT=""
_bf_hint () {
	local -a w=(${(z)BUFFER})
	local cmd=${w[1]} msg="" n nl=$'\n'
	if [[ -n $cmd && -n ${_BF_USAGE[$cmd]} && $BUFFER == "$cmd"[[:space:]]* ]]
	then
		msg="${_BF_USAGE[$cmd]}${_BF_DESC[$cmd]:+  —  ${_BF_DESC[$cmd]}}"
	elif [[ ${#cmd} -ge 3 && $BUFFER != *[[:space:]]* ]]
	then
		local -a hits=(${(ko)_BF_USAGE[(I)*${(b)cmd}*]})
		for n in ${hits[1,5]}
		do
			msg+="${msg:+$nl}${_BF_USAGE[$n]}${_BF_DESC[$n]:+  —  ${_BF_DESC[$n]}}"
		done
		(( ${#hits} > 5 )) && msg+="$nl…$(( ${#hits} - 5 )) more (Ctrl+G to search)"
	fi
	# zle clears -M messages on each keypress, so re-show every redraw (only clear once)
	[[ -z $msg && -z $_BF_LAST_HINT ]] && return
	_BF_LAST_HINT=$msg
	zle -M -- "$msg"
}
_bf_hint_reset () { _BF_LAST_HINT="" }
autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-pre-redraw _bf_hint
add-zle-hook-widget line-init _bf_hint_reset

# Tab after a function name shows its usage above the completions
_bf_complete () {
	_message -r "usage: ${_BF_USAGE[$words[1]]}"
	_files
}

_bf_index
if (( $+functions[compdef] ))
then
	for _bf_name in ${(k)_BF_USAGE}
	do
		(( $+functions[$_bf_name] && ! $+commands[$_bf_name] && ! $+_comps[$_bf_name] )) && compdef _bf_complete $_bf_name
	done
	unset _bf_name
fi
