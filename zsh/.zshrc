# Exports
export PATH="$PATH:/Users/matej/.juliaup/bin/"
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
export EDITOR="/opt/homebrew/bin/nvim"
export CC="/opt/homebrew/opt/llvm/bin/clang"
export CXX="/opt/homebrew/opt/llvm/bin/clang++"

# For zathura vimtex
export DBUS_SESSION_BUS_ADDRESS="unix:path=$DBUS_LAUNCHD_SESSION_BUS_SOCKET"


# Plugin manager and pluygin loading
source ~/.config/zsh/zinit.zsh


#Unique history search
setopt HIST_IGNORE_DUPS


# zoxide
# source ~/.config/zsh/zoxide.sh
eval "$(zoxide init zsh)"


# Aliases
source ~/.config/zsh/aliases.zsh


# Deleting and moving by whole words
# HACK: Ctrl+Backspace sends Ctrl+b in Wezterm so it can work in neovim
if [[ $TERM_PROGRAM == "WezTerm" ]]; then
    bindkey "^B" backward-delete-word
else
    bindkey '^[^?' backward-kill-word
fi
local WORDCHARS=${WORDCHARS//[^a-zA-Z]/}
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

bindkey "^k" history-search-backward
bindkey "^j" history-search-forward


# History
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.cache/zsh/history
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups


# Basic auto/tab complete:
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)		# Include hidden files.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*:files:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
compdef '_files -g "*"' bat


# Powelevel10k
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh//.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh


# fzf
[ -f ~/.config/zsh/.fzf.zsh ] && source ~/.config/zsh/.fzf.zsh
# source <(fzf --zsh)
export FZF_DEFAULT_COMMAND='fd --hidden --type f --exclude .git --exclude Library'


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/matej/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/matej/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/matej/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/matej/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# make thefuck work
eval $(thefuck --alias)


# activate python venv
find_and_activate_venv() {
    # Start in the current directory
    local dir=$(pwd)

    # Traverse upwards until .venv is found or you reach the root
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.venv/bin" ]]; then
            # If .venv is found, activate it
            echo "Activating virtual environment in: $dir/.venv"
            source "$dir/.venv/bin/activate"
            return
        fi
        # Move up to the parent directory
        dir=$(dirname "$dir")
    done

    # If no .venv is found
    echo "No .venv found in the directory tree."
}

# Create an alias to call the function easily
alias venv='find_and_activate_venv'


# # Carapace autocompletion
# export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional
# zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
# source <(carapace _carapace)
#

source "/Users/matej/.deno/env"

# API keys etc. live outside the dotfiles repo (see ~/.config/.gitignore)
[ -f ~/.config/zsh/.secrets.zsh ] && source ~/.config/zsh/.secrets.zsh
