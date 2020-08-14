ZSH_THEME="lambda-mod"
plugins=(git)

# Aliases
alias vim="nvim"
alias bell="tput bel"
alias zshconfig="vim ~/.zshrc"
alias zshreload="source ~/.zshrc"
alias awsconfig-print="cat ~/.aws/config"
alias awsconfig-edit="vim ~/.aws/config"

# Virtualenvwrapper
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME/Development
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
export VIRTUALENVWRAPPER_VIRTUALENV=/usr/local/bin/virtualenv
source /usr/local/bin/virtualenvwrapper.sh
