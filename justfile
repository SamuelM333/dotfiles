default:
    @just --list

# Generate shell completions for CLI tools
generate-completions:
    #!/usr/bin/env bash
    echo "==> Generating Zsh completions..."
    mkdir -p ~/.zsh/completions

    if command -v just &> /dev/null; then
        just --completions zsh > ~/.zsh/completions/_just
    fi

    if command -v gh &> /dev/null; then
        gh completion -s zsh > ~/.zsh/completions/_gh
    fi

    if command -v glab &> /dev/null; then
        glab completion -s zsh > ~/.zsh/completions/_glab
    fi

    if command -v docker &> /dev/null; then
        docker completion zsh > ~/.zsh/completions/_docker
    fi

    if command -v podman &> /dev/null; then
        podman completion zsh > ~/.zsh/completions/_podman
    fi

    if command -v terraform &> /dev/null; then
        echo '#compdef terraform' > ~/.zsh/completions/_terraform
        echo 'autoload -U +X bashcompinit && bashcompinit' >> ~/.zsh/completions/_terraform
        echo 'complete -o nospace -C $(which terraform) terraform' >> ~/.zsh/completions/_terraform
    fi

    if command -v nomad &> /dev/null; then
        echo '#compdef nomad' > ~/.zsh/completions/_nomad
        echo 'autoload -U +X bashcompinit && bashcompinit' >> ~/.zsh/completions/_nomad
        echo 'complete -o nospace -C $(which nomad) nomad' >> ~/.zsh/completions/_nomad
    fi

    if command -v vault &> /dev/null; then
        echo '#compdef vault' > ~/.zsh/completions/_vault
        echo 'autoload -U +X bashcompinit && bashcompinit' >> ~/.zsh/completions/_vault
        echo 'complete -o nospace -C $(which vault) vault' >> ~/.zsh/completions/_vault
    fi
    echo "==> Completions generated successfully!"

install-software:
    @echo "==> Ensuring Flathub remote exists..."
    flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    @echo "==> Installing software from Brewfile..."
    brew bundle --jobs auto
    @echo "==> All software installed successfully!"

apply-configs:
    @echo "==> Checking Proton Pass authentication..."
    @pass-cli test || (echo "Please run 'pass-cli login' first!" && exit 1)
    @echo "==> Applying configurations with chezmoi..."
    chezmoi apply
    @echo "==> Configurations applied successfully!"

config-git:
    git config --global user.email "contact@samuelmurillo.xyz"
    git config --global user.name "Samuel Murillo"


bootstrap: install-software apply-configs config-git generate-completions
    @echo "==> Silverblue development environment fully bootstrapped!"
