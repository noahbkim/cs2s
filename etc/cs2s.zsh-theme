# An adaptation of Dieter that addresses minor QOL issues in Docker
# https://github.com/ohmyzsh/ohmyzsh/blob/master/themes/dieter.zsh-theme

typeset -g -A host_repr

# translate hostnames into shortened, colorcoded strings
host_repr=('dieter-ws-a7n8x-arch' "%{$fg_bold[green]%}ws" 'dieter-p4sci-arch' "%{$fg_bold[blue]%}p4")

# local time, color coded by last return code
time_enabled="%(?.%{$fg[green]%}.%{$fg[red]%})%*%{$reset_color%}"
time_disabled="%{$fg[green]%}%*%{$reset_color%}"
time=$time_enabled

# user part, color coded by privileges
local user="%(!.%{$fg[blue]%}.%{$fg[blue]%})%n%{$reset_color%}"

# Hostname part.  compressed and colorcoded per host_repr array
# if not found, regular hostname in default color
local host="@${host_repr[$HOST]:-$HOST}%{$reset_color%}"

# Compacted $PWD
local pwd="%{$fg[blue]%}%0~%{$reset_color%}"

PROMPT='${return_code}${time} ${user}${host} ${pwd} '

# i would prefer 1 icon that shows the "most drastic" deviation from HEAD,
# but lets see how this works out
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[yellow]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[green]%} %{$fg[yellow]%}?%{$fg[green]%}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[green]%}"

# main change for cs2s
# prefix command with exit code if >0
return_code_enabled="%(?..%{$fg[red]%}%?%{$reset_color%} )"
return_code_disabled=
return_code=$return_code_enabled

function accept-line-or-clear-warning () {
	if [[ -z $BUFFER ]]; then
		time=$time_disabled
		return_code=$return_code_disabled
	else
		time=$time_enabled
		return_code=$return_code_enabled
	fi
	zle accept-line
}
zle -N accept-line-or-clear-warning
bindkey '^M' accept-line-or-clear-warning