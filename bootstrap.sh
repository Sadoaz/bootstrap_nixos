set -euo pipefail

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

DEFAULT_DIR="$HOME/nixos-dotfiles"
REPO_URL="git@github.com:Sadoaz/nixos-dotfiles.git"
echo "Cloner repo med nix shell: $REPO_URL"
nix shell nixpkgs#git -c git clone "$REPO_URL" "$DEFAULT_DIR"

SRC_HARDWARE="/etc/nixos/hardware-configuration.nix"
DEST_HARDWARE="$DEFAULT_DIR/hosts/laptop/hardware-configuration.nix"

if [ -f "$SRC_HARDWARE" ]; then
  echo "Kopierer hardware-configuration fra $SRC_HARDWARE til $DEST_HARDWARE"
  cp "$SRC_HARDWARE" "$DEST_HARDWARE"
else
  echo "❌ Fant ikke $SRC_HARDWARE – hopper over kopiering"
fi

if ! flatpak list | grep -q org.signal.Signal; then
  echo "Installerer Signal fra Flathub..."
  flatpak install -y flathub org.signal.Signal
  sudo flatpak override --env=SIGNAL_PASSWORD_STORE=gnome-libsecret org.signal.Signal
else
  echo "Signal er allerede installert."
fi

echo "Rebuilder system med flake ~/nixos-dotfiles#laptop"
sudo nixos-rebuild switch --flake ~/nixos-dotfiles#laptop

echo "Konfigurerer git globalt..."
git config --global user.name "Sadoaz"
git config --global user.email "sadoazsosial@gmail.com"

echo
echo "✅ Alt ferdig. Maskinen er konfigurert."
