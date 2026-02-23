# Platform detection
IS_MACOS=false; [[ "$(uname -s)" == "Darwin" ]] && IS_MACOS=true

# BEGIN ANSIBLE MANAGED BLOCK
# Load homebrew shell variables (macOS only)
if $IS_MACOS && [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  export HOMEBREW_NO_INSECURE_REDIRECT=1
  export HOMEBREW_CASK_OPTS=--require-sha
  export HOMEBREW_DIR=/opt/homebrew
  export HOMEBREW_BIN=/opt/homebrew/bin
  # Prefer GNU binaries to Macintosh binaries.
  export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
fi

# Load python shims
command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init -)"

# Load ruby shims
command -v rbenv >/dev/null 2>&1 && eval "$(rbenv init -)"

# Add datadog devtools binaries to the PATH
export PATH="$HOME/dd/devtools/bin:$PATH"

# Point GOPATH to our go sources
export GOPATH="$HOME/go"

# Add binaries that are go install-ed to PATH
export PATH="$GOPATH/bin:$PATH"

# Point DATADOG_ROOT to ~/dd symlink
export DATADOG_ROOT="$HOME/dd"

# Tell the devenv vm to mount $GOPATH/src rather than just dd-go
export MOUNT_ALL_GO_SRC=1

# store key in the login keychain instead of aws-vault managing a hidden keychain
export AWS_VAULT_KEYCHAIN_NAME=login

# tweak session times so you don't have to re-enter passwords every 5min
export AWS_SESSION_TTL=24h
export AWS_ASSUME_ROLE_TTL=1h

# Helm switch from storing objects in kubernetes configmaps to
# secrets by default, but we still use the old default.
export HELM_DRIVER=configmap

# Go 1.16+ sets GO111MODULE to off by default with the intention to
# remove it in Go 1.18, which breaks projects using the dep tool.
# https://blog.golang.org/go116-module-changes
export GO111MODULE=auto
export GOPRIVATE=github.com/DataDog
# Configure Go to pull go.ddbuild.io packages.
export GOPROXY=binaries.ddbuild.io,https://proxy.golang.org,direct
export GONOSUMDB=github.com/DataDog,go.ddbuild.io
# END ANSIBLE MANAGED BLOCK
# GitLab token (macOS keychain only)
if $IS_MACOS && command -v security >/dev/null 2>&1; then
  export GITLAB_TOKEN=$(security find-generic-password -a ${USER} -s gitlab_token -w 2>/dev/null)
fi
[ -f ~/.config/gitsign/include.sh ] && source ~/.config/gitsign/include.sh

# Update with your preference
export DATADOG_ROOT=~/dd

# Force certain more-secure behaviours from homebrew (macOS only)
if $IS_MACOS; then
  export HOMEBREW_NO_INSECURE_REDIRECT=1
  export HOMEBREW_CASK_OPTS=--require-sha
fi

# Add devtools binaries in your PATH, so you have access to 'to-staging' and 'branches-status'
# !!! Make sure that this is *after* adding homebrew to PATH if you have brew. !!!
export PATH="$PATH:$DATADOG_ROOT/devtools/bin"

# Cross-platform URL opener
_open_url() {
  if $IS_MACOS; then open "$1"
  elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$1"
  else echo "$1"
  fi
}

function openpr() {
    local BRANCH=$(git rev-parse --abbrev-ref HEAD)
    _open_url "https://github.com/DataDog/web-ui/compare/preprod...$BRANCH"
}

function openpr-ddsource() {
    local BRANCH=$(git rev-parse --abbrev-ref HEAD)
    _open_url "https://github.com/DataDog/dd-source/compare/main...$BRANCH"
}

function gcb() {
  local branch_name="$1"

  if [[ -z "$branch_name" ]]; then
    echo -n "Enter branch name: "
    read branch_name
  fi

  if [[ -z "$branch_name" ]]; then
    echo "Branch name cannot be empty."
    return 1
  fi

  git checkout -b "hasan.toor/$branch_name"
}

function gpuo() {
  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD)

  if [[ -z "$current_branch" ]]; then
    echo "Couldn't determine the current branch."
    return 1
  fi

  git push -u origin "$current_branch"
}

alias gcm='git commit -m'
alias gaa='git add .'
alias gfp='git fetch origin && git merge origin/preprod'
[ -f "$HOME/.deno/env" ] && . "$HOME/.deno/env"

# Clipboard compatibility (Linux)
if ! $IS_MACOS && command -v xclip >/dev/null 2>&1; then
  alias pbcopy='xclip -selection clipboard'
  alias pbpaste='xclip -selection clipboard -o'
fi

# make sure k -> kubectl
alias k='kubectl'

# STAGING: get a short-lived DB token to clipboard, then port-forward 5432
alias kdb='ddtool auth token orgstore-service-catalog --datacenter us1.staging.dog | pbcopy && \
k port-forward --context=gizmo.us1.staging.dog \
  --namespace=orgstore-service-catalog \
  svc/orgstore-service-catalog-pg-proxy 5432:5432'

# PROD: get token to clipboard, then port-forward 5432
alias kdb-us1='ddtool auth token orgstore-service-catalog --datacenter us1.prod.dog | pbcopy && \
k port-forward --context=komala.us1.prod.dog \
  --namespace=orgstore-service-catalog \
  service/orgstore-service-catalog-pg-proxy 5432:5432'
# Created by `pipx` on 2025-09-23 14:42:41
export PATH="$PATH:$HOME/.local/bin"

# BEGIN SCFW MANAGED BLOCK (macOS only)
if $IS_MACOS && command -v scfw >/dev/null 2>&1; then
  alias npm="scfw run npm"
  alias pip="scfw run pip"
  alias poetry="scfw run poetry"
  export SCFW_DD_AGENT_LOG_PORT="10365"
  export SCFW_DD_LOG_LEVEL="ALLOW"
  export SCFW_HOME="$HOME/.scfw"
fi
# END SCFW MANAGED BLOCK

# Added by Yarn Switch
[ -f "$HOME/.yarn/switch/env" ] && source "$HOME/.yarn/switch/env"

# Personal scripts
export PATH="$HOME/dotfiles/bin:$PATH"

# Display for 3 seconds (3000ms)
alias notify='tmux display-message -d 3000 "Job Done!"'

# ============================================================
# Prompt: ~/path (branch*) $
# ============================================================
autoload -Uz add-zsh-hook vcs_info
setopt prompt_subst

zstyle ':vcs_info:git:*' formats ' (%b%u%c)'
zstyle ':vcs_info:git:*' actionformats ' (%b|%a%u%c)'
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr '*'
zstyle ':vcs_info:git:*' stagedstr '+'

add-zsh-hook precmd vcs_info

PROMPT='%F{cyan}%~%f%F{yellow}${vcs_info_msg_0_}%f %F{white}$%f '
