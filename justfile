# --- Default Recipe ---
default:
    @just --list

install-software:
    @echo "==> Ensuring Flathub remote exists..."
    flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    @echo "==> Installing software from Brewfile..."
    brew bundle --file=Brewfile --no-lock
    @echo "==> All software installed successfully!"

# Apply configurations using chezmoi (with Proton Pass check)
apply-configs:
    @echo "==> Checking Proton Pass authentication..."
    @pass-cli status || (echo "Please run 'pass-cli login' first!" && exit 1)
    @echo "==> Applying configurations with chezmoi..."
    chezmoi apply
    @echo "==> Configurations applied successfully!"

# Master recipe to bootstrap a new machine
bootstrap: install-software apply-configs
    @echo "==> Silverblue development environment fully bootstrapped!"