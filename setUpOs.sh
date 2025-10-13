#!/bin/bash

# ===================================================================================
#
#          FILE: setup_hyprland_neovim.sh
#
#         USAGE: ./setup_hyprland_neovim.sh
#
#   DESCRIPTION: A script to fully set up a fresh Ubuntu 25.04 installation
#                with Hyprland, custom configurations, and Neovim.
#
#       VERSION: 1.0
#       CREATED: 2023-10-27
#      REVISION: ---
#
# ===================================================================================

# --- Colors for output ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Log file ---
LOG_FILE="setup_log.txt"

# --- Function to log messages and check for errors ---
log_action() {
    local message=$1
    local command_to_run=$2
    local action_name=$3

    echo -e "${YELLOW}--- ${message} ---${NC}"
    if eval ${command_to_run}; then
        echo -e "${GREEN}SUCCESS:${NC} ${message}"
        echo "SUCCESS: ${action_name}" >> ${LOG_FILE}
    else
        echo -e "${RED}FAILURE:${NC} ${message}"
        echo "FAILURE: ${action_name}" >> ${LOG_FILE}
        # Optionally, you can have the script exit on any failure
        # exit 1
    fi
    echo "" # for spacing
}

# --- Main Setup Function ---
main() {
    # --- Initial Setup ---
    echo "Starting the setup process..."
    mkdir -p ~/osSetUp
    cd ~/osSetUp || { echo "Failed to create or enter osSetUp directory. Aborting."; exit 1; }
    touch ${LOG_FILE}
    echo "Setup log started at $(date)" > ${LOG_FILE}
    echo "---------------------------------" >> ${LOG_FILE}

    # --- System Update and Upgrade ---
    log_action "Updating package lists" "sudo apt update" "System Update"
    log_action "Upgrading installed packages" "sudo apt upgrade -y" "System Upgrade"

    # --- Install Google Chrome ---
    log_action "Downloading Google Chrome" "wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" "Chrome Download"
    log_action "Installing Google Chrome" "sudo apt install -y ./google-chrome-stable_current_amd64.deb" "Chrome Install"

    # --- Add Up-to-date Toolchain Repository ---
    log_action "Adding Ubuntu toolchain repository" "sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test" "Toolchain Repo Add"
    log_action "Updating package lists after adding repo" "sudo apt update" "Post-Repo Update"
    log_action "Modernizing sources" "sudo apt modernize-sources" "Modernize Sources"

    # --- Set GCC 15 as Default ---
    log_action "Installing Baseline GCC and G++" "sudo apt install -y gcc g++" "GCC Install"
    log_action "Installing GCC 15 and G++ 15" "sudo apt install -y gcc-15 g++-15" "GCC 15 Install"
    log_action "Setting GCC 15 as default for gcc" "sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-15 100" "GCC Alternative"
    log_action "Setting G++ 15 as default for g++" "sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-15 100" "G++ Alternative"

    # --- Install Hyprland Dependencies ---
    log_action "Installing core Hyprland dependencies" "sudo apt install -y meson wget build-essential ninja-build cmake-extras cmake gettext gettext-base fontconfig libfontconfig-dev libffi-dev libxml3-dev libdrm-dev libpixman-1-dev libudev-dev libseat-dev seatd libxcb-dri3-dev libegl-dev libgles2 libegl1-mesa-dev glslang-tools libinput-bin libinput-dev libxcb-composite0-dev libavutil-dev libavcodec-dev libavformat-dev libxcb-ewmh2 libxcb-ewmh-dev libxcb-present-dev libxcb-icccm4-dev libxcb-render-util0-dev libxcb-res0-dev libxcb-xinput-dev libtomlplusplus3 libre2-dev git xdg-desktop-portal-hyprland libzip-dev libcairo2-dev librsvg2-dev libtomlplusplus-dev libpugixml-dev libmagic-dev libwayland-dev libgbm-dev libdisplay-info-dev libxcursor-dev libgtk-4-dev libgtk-3-dev libxcb-errors-dev bison hyprpaper wofi jq dolphin kitty vim-gtk3 curl qt6-base-dev qt6-declarative-dev qt6-wayland-dev nodejs npm ripgrep fd-find mako-notifier pulseaudio pavucontrol python3 python3-pip pipx direnv libsdbus-c++-dev libpam0g-dev ddcutil" "Hyprland Dependencies":

    # --- Build and Install Modern Hyprland Dependencies from Source ---
    mkdir -p hyperlandDependencies
    cd hyperlandDependencies || { echo "Failed to create or enter hyperlandDependencies directory. Aborting."; exit 1; }

    # libxkbcommon
    log_action "Cloning libxkbcommon" "git clone https://github.com/xkbcommon/libxkbcommon.git" "libxkbcommon Clone"
    cd libxkbcommon || exit 1
    log_action "Configuring libxkbcommon" "meson setup build -Denable-x11=false" "libxkbcommon Configure"
    log_action "Building libxkbcommon" "ninja -C build" "libxkbcommon Build"
    log_action "Installing libxkbcommon" "sudo ninja -C build install" "libxkbcommon Install"
    cd ..

    # libinput
    log_action "Cloning libinput" "git clone https://gitlab.freedesktop.org/libinput/libinput.git" "libinput Clone"
    cd libinput || exit 1
    log_action "Configuring libinput" "meson setup build" "libinput Configure"
    log_action "Building libinput" "ninja -C build" "libinput Build"
    log_action "Installing libinput" "sudo ninja -C build install" "libinput Install"
    cd ..

    # wayland-protocols
    log_action "Cloning wayland-protocols" "git clone https://gitlab.freedesktop.org/wayland/wayland-protocols.git" "wayland-protocols Clone"
    cd wayland-protocols || exit 1
    log_action "Configuring wayland-protocols" "meson setup build" "wayland-protocols Configure"
    log_action "Building wayland-protocols" "ninja -C build" "wayland-protocols Build"
    log_action "Installing wayland-protocols" "sudo ninja -C build install" "wayland-protocols Install"
    cd ..

    # Hyprland components
    HYPR_COMPONENTS=("hyprutils" "hyprlang" "hyprcursor" "hyprgraphics" "hyprwayland-scanner" "aquamarine")
    for component in "${HYPR_COMPONENTS[@]}"; do
        log_action "Cloning ${component}" "git clone https://github.com/hyprwm/${component}.git" "${component} Clone"
        cd "${component}" || exit 1
        log_action "Configuring ${component}" "cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -B build" "${component} Configure"
        log_action "Building ${component}" "cmake --build build --config Release --target all -j$(nproc)" "${component} Build"
        log_action "Installing ${component}" "sudo cmake --install build" "${component} Install"
        cd ..
    done
    cd ..

    # --- Build and Install Hyprland ---
    log_action "Cloning Hyprland" "git clone --recursive https://github.com/hyprwm/Hyprland" "Hyprland Clone"
    cd Hyprland || exit 1
    log_action "Updating Hyprland submodules" "git submodule update --init --recursive" "Hyprland Submodules"
    log_action "Building Hyprland" "make all" "Hyprland Build"
    log_action "Installing Hyprland" "sudo make install" "Hyprland Install"
    cd ..

    # --- Setup hyperland-protocols ---
    log_action "Clone bulid and install hyprland-protocols all at once" "git clone https://github.com/hyprwm/hyprland-protocols && cd hyprland-protocols && meson setup build && sudo meson install -C build" "Install hyprland-protocols"

    # --- Setup Hyprlock ---
    cd ~/osSetUp
    log_action "Clone hyprlock soruce" "git clone https://github.com/hyprwm/hyprlock.git && cd hyprlock" "Clone hyprlock"
    log_action "Bulid hyprlock from source" "cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -S . -B ./build && cmake --build ./build --config Release --target hyprlock -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF`" "hyprlock bulid"
    log_action "Install hyprlock from source" "sudo cmake --install build" "hyprland install"

    # --- Setup Hypridle ---
    cd ~/osSetUp
    log_action "Clone hypridle soruce" "git clone https://github.com/hyprwm/hypridle.git && cd hypridle" "Clone hypridle"
    log_action "Bulid hypridle from source" "cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -S . -B ./build && cmake --build ./build --config Release --target hypridle -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF`" "hypridle bulid"
    log_action "Install hypridle from source" "sudo cmake --install build" "hypridle install"



    # --- Install Nerd Fonts ---
    log_action "Downloading JetBrainsMono Nerd Font" "wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip" "Nerd Font Download"
    log_action "Creating fonts directory" "mkdir -p ~/.local/share/fonts" "Font Dir Create"
    log_action "Unzipping Nerd Font" "unzip -o JetBrainsMono.zip -d ~/.local/share/fonts/" "Nerd Font Unzip"
    log_action "Updating font cache" "fc-cache -fv" "Font Cache Update"

    # --- Get Config Files ---
    log_action "Creating hypr config directory" "mkdir -p ~/.config/hypr" "Hypr Config Dir"
    cd ~/.config/hypr || exit 1
    log_action "Cloning config files" "git clone https://github.com/valenteEngineering/lentilLandConfigs.git ." "Config Clone"
    log_action "Creating waybar symlink" "ln -s ~/.config/hypr/waybar ~/.config/waybar" "Waybar Symlink"
    cd ~/osSetUp || exit 1

    # --- Set up SDDM ---
    log_action "Pre-configuring SDDM" "echo \"sddm shared/default-display-manager select /usr/bin/sddm\" | sudo debconf-set-selections" "SDDM Pre-config"
    log_action "Installing SDDM" "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y sddm" "SDDM Install"
    
    # --- Setup user i2c control ---
    log_action "Give i2c usermod to user" "sudo usermod -aG i2c $USER" "I2C Usermod"

    # --- Git Credential Manager ---
    log_action "Downloading Git Credential Manager" "wget https://github.com/git-ecosystem/git-credential-manager/releases/download/v2.6.1/gcm-linux_amd64.2.6.1.deb" "GCM Download"
    log_action "Installing Git Credential Manager" "sudo dpkg -i gcm-linux_amd64.2.6.1.deb" "GCM Install"
    log_action "Configuring Git Credential Manager" "git config --global credential.credentialStore secretservice" "GCM Config Store"
    log_action "Finalizing Git Credential Manager setup" "git-credential-manager configure" "GCM Configure"

    # --- Lazy Git ---
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
    log_action "Downloading LazyGit" "curl -Lo lazygit.tar.gz 'https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz'" "LG Download"
    log_action "Unpacking LazyGit" "tar xf lazygit.tar.gz lazygit" "LG Unpack"
    log_action "Install LazGit" "sudo install lazygit -D -t /usr/local/bin/" "LG Install"

    # --- Neovim Setup ---
    log_action "Downloading Neovim AppImage" "curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage" "Neovim Download"
    log_action "Making Neovim AppImage executable" "chmod u+x nvim-linux-x86_64.appimage" "Neovim Executable"
    log_action "Creating Neovim opt directory" "sudo mkdir -p /opt/nvim" "Neovim Opt Dir"
    log_action "Moving Neovim to opt" "sudo mv nvim-linux-x86_64.appimage /opt/nvim/nvim" "Neovim Move"
    log_action "Adding Neovim to PATH in .bashrc" "echo 'export PATH=\"\$PATH:/opt/nvim/\"' >> ~/.bashrc" "Neovim PATH"
    log_action "Creating vim alias for nvim in .bashrc" "echo 'alias vim=nvim' >> ~/.bashrc" "Neovim Alias"

    # --- Install LnVim Config ---
    log_action "Creating nvim config directory" "mkdir -p ~/.config/nvim" "Nvim Config Dir"
    cd ~/.config/nvim || exit 1
    log_action "Cloning LNvim config" "git clone https://github.com/valenteEngineering/LNvim_Config.git ." "LNvim Clone"

    # --- Setup DirEnv ---
    log_action "Setting up direnv for automatic per folder environment setup" "echo 'eval \"\$(direnv hook bash)\"\' >> ~/.bashrc" "DirEnv Hook"

    # --- Up python ---
    log_action "Install pipx for to install uv" "sudo pipx ensurepath --global" "Install pipx"
    log_action "Install UV python manager" "pipx install uv" "Install UV"
    log_action "creating alias for setting up environment" "echo 'alias s=. ./.venv/bin/activate' >> ~/.bashrc" "Neovim Alias"

    # --- Final Summary ---
    echo -e "\n\n${YELLOW}=====================================${NC}"
    echo -e "${YELLOW}           SETUP SUMMARY           ${NC}"
    echo -e "${YELLOW}=====================================${NC}"
    
    while IFS= read -r line; do
        if [[ $line == SUCCESS:* ]]; then
            echo -e "${GREEN}${line}${NC}"
        elif [[ $line == FAILURE:* ]]; then
            echo -e "${RED}${line}${NC}"
        else
            echo "$line"
        fi
    done < ~/osSetUp/${LOG_FILE}

    echo -e "\n${YELLOW}------------------------------------${NC}"
    echo "Please reboot your system for all changes to take effect."
    echo "Remember to run 'source ~/.bashrc' or open a new terminal for Neovim path changes to apply in the current session."
}

# --- Execute Main Function ---
main
