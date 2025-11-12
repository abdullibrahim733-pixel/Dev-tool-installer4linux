#!/usr/bin/env bash
# ===============================================
# 🧙 DevWizard — Arch/Garuda Dev & (Optional) Security Setup
# + fastfetch-style system info banner at startup
# ===============================================
# WARNING: Security tools are dual-use. Only use them legally and with permission.
# ===============================================

set -euo pipefail

# -------------------------
# Colors
# -------------------------
GREEN="\e[32m"
CYAN="\e[36m"
MAGENTA="\e[35m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"
BOLD="\e[1m"

# -------------------------
# Utility functions
# -------------------------
print_header() {
  clear
  echo -e "${CYAN}"
  echo "=============================================================="
  echo "   🧙 DevWizard — Arch/Garuda Dev & (Optional) Security Setup  "
  echo "=============================================================="
  echo -e "${RESET}"
}

confirm() {
  # Usage: confirm "Prompt message"
  read -r -p "$1 [y/N]: " response
  case "$response" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

ensure_yay() {
  if ! command -v yay &>/dev/null; then
    echo -e "${YELLOW}yay (AUR helper) not found — installing...${RESET}"
    sudo pacman -S --needed --noconfirm base-devel git || { echo "pacman failed. Please ensure you have network."; exit 1; }
    tmpdir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
  fi
}

install_pacman() {
  echo -e "${GREEN}Installing (pacman): $*${RESET}"
  sudo pacman -S --noconfirm --needed "$@"
}

install_yay() {
  ensure_yay
  echo -e "${GREEN}Installing (AUR via yay): $*${RESET}"
  yay -S --noconfirm --needed "$@"
}

# Add BlackArch repo helper
add_blackarch_repo() {
  echo -e "${YELLOW}This will add the BlackArch repository to /etc/pacman.conf and import keys.${RESET}"
  echo -e "${RED}BlackArch contains thousands of security tools and may cause package conflicts.${RESET}"
  if confirm "Proceed to add BlackArch repo? (only do this if you know the risks)"; then
    curl -O https://blackarch.org/strap.sh
    chmod +x strap.sh
    sudo ./strap.sh
    rm -f strap.sh
    echo -e "${GREEN}BlackArch repo added. Updating databases...${RESET}"
    sudo pacman -Syyu
  else
    echo -e "${MAGENTA}Skipped adding BlackArch repository.${RESET}"
  fi
}

# -------------------------
# System info banner (fastfetch-style fallback)
# -------------------------
show_sysinfo_banner() {
  # A compact text/info "banner" that mimics fastfetch/neofetch style.
  OS_INFO="$(. /etc/os-release 2>/dev/null && echo "$NAME $VERSION" || echo "Unknown OS")"
  KERNEL="$(uname -r)"
  UPTIME="$(uptime -p 2>/dev/null || echo "unknown")"
  SHELL_NAME="$(basename "$SHELL" 2>/dev/null || echo 'unknown')"
  HOST="$(hostname 2>/dev/null || echo 'unknown')"
  CPU="$(awk -F: '/model name/ {print $2; exit}' /proc/cpuinfo 2>/dev/null | sed 's/^[ \t]*//')"
  MEM="$(free -h | awk '/Mem:/ {print $3 \" / \" $2}')"
  DISK="$(df -h --output=source,fstype,size,used,avail,target / | tail -n1 2>/dev/null || true)"
  PKGS="$(pacman -Qq 2>/dev/null | wc -l || echo '?')"
  GPU="$(lspci 2>/dev/null | grep -E 'VGA|3D' || echo 'unknown')"
  IP_INFO="$(ip -brief addr show 2>/dev/null | awk '{print $1" "$3}' | sed -n '1,3p' || true)"

  cat <<BANNER
${MAGENTA}┌───────────────────────────────────────────────────────────────┐${RESET}
${MAGENTA}│${RESET} ${BOLD}DevWizard${RESET} — quick system snapshot for $USER on ${HOST}
${MAGENTA}└───────────────────────────────────────────────────────────────┘${RESET}

${CYAN}OS:${RESET}      ${OS_INFO}
${CYAN}Kernel:${RESET}  ${KERNEL}
${CYAN}Uptime:${RESET}  ${UPTIME}
${CYAN}Shell:${RESET}   ${SHELL_NAME}
${CYAN}Packages:${RESET} ${PKGS}
${CYAN}CPU:${RESET}     ${CPU}
${CYAN}Memory:${RESET}  ${MEM}
${CYAN}Disk(/):${RESET}  ${DISK}
${CYAN}GPU:${RESET}     $(echo "${GPU}" | sed 's/^/ /')
${CYAN}Network:${RESET} ${IP_INFO:-'No interfaces found'}

${YELLOW}Note:${RESET} This banner uses built-in tools; run the menu below to install tools (fastfetch/neofetch, etc.)
BANNER
}

# -------------------------
# Predefined security tools and common list
# -------------------------
COMMON_PENTEST_TOOLS=(nmap amass nikto uniscan sqlmap metasploit-framework john hydra wireshark-qt aircrack-ng burpsuite-community)

# -------------------------
# Main interactive menu
# -------------------------
print_header
show_sysinfo_banner

echo -e "${MAGENTA}WARNING:${RESET} The security tools below can be used for penetration testing. Only use them on systems you own or have explicit permission to test."
echo ""
echo -e "${YELLOW}Choose what to install (enter numbers separated by spaces):${RESET}"
cat <<'MENU'
  1) 🧩 Essential build tools
  2) 🐍 Python + pip + virtualenv + Jupyter
  3) 🧠 Node.js + npm + yarn
  4) 🐳 Docker + Docker Compose
  5) 🧱 Databases (PostgreSQL, MariaDB, SQLite)
  6) 🧑‍💻 Editors (Neovim, VS Code, PyCharm)
  7) 📦 VirtualBox
  8) 🎨 Theming (fonts, icons, Starship prompt)
  9) 🎬 GUI tools (file manager, image viewer, VLC, etc.)
 10) 🚀 Install everything (developer stack)
 11) 🔒 Install selected security/tools (nmap, amass, nikto, uniscan, sqlmap, metasploit, etc.)
 12) 🛡️ Add BlackArch repo (optional) & install BlackArch categories / all
 13) 🔧 Install common pentest tools (automated mix of official + AUR)
 0) ❌ Exit
MENU

read -r -p "Enter choices: " choices_input
read -r -a choices_arr <<<"$choices_input"

for choice in "${choices_arr[@]}"; do
  case "$choice" in
    1)
      print_header
      echo -e "${GREEN}Installing essential build tools...${RESET}"
      install_pacman base-devel git cmake make gcc g++ clang pkgconf fakeroot
      ;;
    2)
      print_header
      echo -e "${GREEN}Installing Python tools...${RESET}"
      install_pacman python python-pip python-virtualenv jupyter-notebook
      ;;
    3)
      print_header
      echo -e "${GREEN}Installing Node.js, npm, yarn...${RESET}"
      install_pacman nodejs npm yarn
      ;;
    4)
      print_header
      echo -e "${GREEN}Installing Docker...${RESET}"
      install_pacman docker docker-compose
      sudo systemctl enable --now docker
      sudo usermod -aG docker "$USER"
      ;;
    5)
      print_header
      echo -e "${GREEN}Installing databases...${RESET}"
      install_pacman postgresql mariadb sqlite
      ;;
    6)
      print_header
      echo -e "${GREEN}Installing Editors (Neovim, VS Code, PyCharm)...${RESET}"
      install_pacman neovim code
      ensure_yay
      yay -S --noconfirm pycharm-community-edition
      ;;
    7)
      print_header
      echo -e "${GREEN}Installing VirtualBox...${RESET}"
      install_pacman virtualbox virtualbox-host-dkms linux-headers
      sudo gpasswd -a "$USER" vboxusers || true
      # start/enable vbox service only if available
      if systemctl list-unit-files | grep -q vboxservice; then
        sudo systemctl enable --now vboxservice || true
      fi
      ;;
    8)
      print_header
      echo -e "${GREEN}Installing theming tools, fonts, and Starship prompt...${RESET}"
      install_pacman zsh starship alacritty ttf-jetbrains-mono-nerd papirus-icon-theme
      ensure_yay
      # catppuccin theme may be in AUR
      yay -S --noconfirm catppuccin-gtk-theme || true
      chsh -s /bin/zsh || true
      if ! grep -q "starship init zsh" ~/.zshrc 2>/dev/null; then
        echo 'eval "$(starship init zsh)"' >> ~/.zshrc
      fi
      ;;
    9)
      print_header
      echo -e "${GREEN}Installing GUI tools...${RESET}"
      install_pacman thunar imv vlc gnome-disk-utility pavucontrol file-roller gparted
      ;;
    10)
      print_header
      echo -e "${GREEN}Installing EVERYTHING (developer stack)...${RESET}"
      install_pacman base-devel git cmake make gcc g++ clang pkgconf fakeroot \
        python python-pip python-virtualenv jupyter-notebook nodejs npm yarn \
        postgresql mariadb sqlite docker docker-compose neovim code zsh starship alacritty \
        ttf-jetbrains-mono-nerd papirus-icon-theme thunar imv vlc gnome-disk-utility file-roller pavucontrol gparted \
        virtualbox virtualbox-host-dkms linux-headers
      ensure_yay
      yay -S --noconfirm pycharm-community-edition catppuccin-gtk-theme || true
      sudo systemctl enable --now docker || true
      sudo usermod -aG docker,vboxusers "$USER" || true
      ;;
    11)
      print_header
      echo -e "${CYAN}Security tool installer — select tools to install (space-separated).${RESET}"
      echo "Quick list: nmap amass nikto uniscan sqlmap metasploit-framework john hydra wireshark-qt aircrack-ng burpsuite-community"
      read -r -p "Enter tool names to install (or 'all' for the common list): " tlist
      if [[ "$tlist" == "all" ]]; then
        selected=("${COMMON_PENTEST_TOOLS[@]}")
      else
        read -r -a selected <<<"$tlist"
      fi

      echo -e "${YELLOW}Installing selected security tools...${RESET}"
      ensure_yay
      for pkg in "${selected[@]}"; do
        # Try pacman first, then AUR
        if pacman -Si "$pkg" &>/dev/null; then
          install_pacman "$pkg"
        else
          echo -e "${MAGENTA}$pkg not found in official repos — trying AUR (yay)...${RESET}"
          install_yay "$pkg" || echo -e "${RED}Failed to install $pkg via AUR. Please check package name.${RESET}"
        fi
      done
      ;;
    12)
      print_header
      echo -e "${YELLOW}BlackArch integration (advanced).${RESET}"
      echo -e "${RED}IMPORTANT:${RESET} Adding BlackArch will add thousands of pentest packages and may conflict with repositories. Only proceed if you understand the risk."
      if confirm "Do you want to add the BlackArch repo now?"; then
        add_blackarch_repo
        if confirm "Install a BlackArch category (recommended) instead of all tools?"; then
          echo "Example categories: web net crypto exploitation forensics reverse wireless"
          read -r -p "Enter category name to install (or 'list' to show sample): " bcat
          if [[ "$bcat" == "list" ]]; then
            echo "Sample categories: web net crypto exploitation forensics reverse wireless"
            read -r -p "Enter category to install: " bcat
          fi
          sudo pacman -S --noconfirm "blackarch-$bcat" || echo -e "${RED}Failed to install category $bcat${RESET}"
        else
          if confirm "Install the entire BlackArch meta-package (huge)?"; then
            sudo pacman -S --noconfirm blackarch || echo -e "${RED}BlackArch install failed${RESET}"
          else
            echo -e "${MAGENTA}Skipped full BlackArch install.${RESET}"
          fi
        fi
      else
        echo -e "${MAGENTA}Skipped adding BlackArch.${RESET}"
      fi
      ;;
    13)
      print_header
      echo -e "${GREEN}Installing common pentest tools (automated)...${RESET}"
      ensure_yay
      for pkg in "${COMMON_PENTEST_TOOLS[@]}"; do
        if pacman -Si "$pkg" &>/dev/null; then
          install_pacman "$pkg"
        else
          echo -e "${MAGENTA}$pkg not in official repos → using AUR${RESET}"
          install_yay "$pkg" || echo -e "${RED}Failed to install $pkg via AUR${RESET}"
        fi
      done
      ;;
    0)
      echo -e "${YELLOW}Exiting DevWizard.${RESET}"
      exit 0
      ;;
    *)
      echo -e "${MAGENTA}Invalid option: $choice${RESET}"
      ;;
  esac
done

# Final reminders and tips
echo ""
echo -e "${CYAN}=============================================================="
echo " 🎉 DevWizard run complete!"
echo " - Reboot or logout to apply group changes (docker, vboxusers)."
echo " - If you installed BlackArch, check /etc/pacman.conf and mirror configs."
echo " - Use these tools responsibly and only against systems you are authorized to test."
echo -e "${RESET}"
