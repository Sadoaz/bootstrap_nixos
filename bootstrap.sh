set -euo pipefail

# 1. Opprett .XCompose med dine tilpassede sekvenser
XCOMPOSE_PATH="$HOME/.XCompose"
cat > "$XCOMPOSE_PATH" <<EOF
<Cancel> <0> <2> <g> : "Ø"
<Cancel> <0> <3> <c> : "ø"
<Cancel> <0> <2> <t> : "å"
<Cancel> <0> <2> <u> : "æ"
<Cancel> <0> <1> <y> : "Æ"
<Cancel> <0> <1> <x> : "Å"
EOF

echo "✅ Skrev Compose-innstillinger til $XCOMPOSE_PATH"

# 2. Generer SSH-nøkkel hvis den ikke finnes
KEY_PATH="$HOME/.ssh/id_ed25519"
if [ ! -f "$KEY_PATH" ]; then
  echo "Genererer ny SSH-nøkkel..."
  ssh-keygen -t ed25519 -C "sadoazsosial@gmail.com" -f "$KEY_PATH" -N ""
  eval "$(ssh-agent -s)"
  ssh-add "$KEY_PATH"
else
  echo "SSH-nøkkel finnes allerede."
fi

echo
echo "Offentlig nøkkel:"
cat "${KEY_PATH}.pub"
echo

echo "Åpner GitHub SSH key settings..."
firefox https://github.com/settings/keys &

echo "Åpner 1Password-utvidelsen i Firefox..."
firefox "https://addons.mozilla.org/en-US/firefox/addon/1password-x-password-manager/" &

echo "Åpner ChatGPT i Firefox..."
firefox "https://chat.openai.com" &

echo
echo "🔐 Når du har lagt til SSH-nøkkelen i GitHub, skriv 'done' og trykk Enter for å fortsette."
while true; do
  read -r -p "> " input
  if [[ "$input" == "done" ]]; then
    break
  else
    echo "Skriv 'done' når du er klar til å gå videre."
  fi
done

# 3. Clone dotfiles-repo
DEFAULT_DIR="$HOME/nixos-dotfiles"
REPO_URL="git@github.com:Sadoaz/nixos-dotfiles.git"
echo "Cloner repo med nix shell: $REPO_URL"
git clone "$REPO_URL" "$DEFAULT_DIR"

SRC_HARDWARE="/etc/nixos/hardware-configuration.nix"
DEST_HARDWARE="$DEFAULT_DIR/hosts/laptop/hardware-configuration.nix"

if [ -f "$SRC_HARDWARE" ]; then
  echo "Kopierer hardware-configuration fra $SRC_HARDWARE til $DEST_HARDWARE"
  cp "$SRC_HARDWARE" "$DEST_HARDWARE"
else
  echo "❌ Fant ikke $SRC_HARDWARE – hopper over kopiering"
fi


# 6. Rebuild systemet med flake
echo "Rebuilder system med flake ~/nixos-dotfiles#laptop"
sudo nixos-rebuild switch --flake ~/nixos-dotfiles#laptop

# 7. Konfigurer git
echo "Konfigurerer git globalt..."
git config --global user.name "Sadoaz"
git config --global user.email "sadoazsosial@gmail.com"

# 8. Fiks eierskap på neovim undo-dir
echo
echo "Fikser eierskap på ~/.local/state/nvim/undo hvis nødvendig..."
if [ -d "$HOME/.local/state/nvim/undo" ]; then
  sudo chown -R "$USER:$(id -gn)" "$HOME/.local/state/nvim/undo"
  chmod 700 "$HOME/.local/state/nvim/undo"
fi



flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
# 4. Installer Signal via Flatpak
if ! flatpak list | grep -q org.signal.Signal; then
  echo "Installerer Signal fra Flathub..."
  flatpak install -y flathub org.signal.Signal
fi

# 5. Sett Flatpak override slik at Signal får tilgang til .XCompose
sudo flatpak override org.signal.Signal --filesystem=$HOME/.XCompose:ro
sudo flatpak override org.signal.Signal --env=SIGNAL_PASSWORD_STORE=gnome-libsecret

flatpak install flathub com.moonlight_stream.Moonlight

git clone https://github.com/arcticicestudio/nord-tmux.git ~/.tmux/themes/nord-tmux

tmux source-file ~/.tmux.conf
asusctl -k high


echo
echo "✅ Alt ferdig. Compose-tast skal nå fungere i Signal også."
