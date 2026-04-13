default:
    @just --list

install-software:
    @echo "==> Ensuring Flathub remote exists..."
    flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    @echo "==> Installing software from Brewfile..."
    brew bundle --file=Brewfile
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


bootstrap: install-software apply-configs config-git
    @echo "==> Silverblue development environment fully bootstrapped!"
