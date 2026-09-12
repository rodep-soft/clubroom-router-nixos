{ config, lib, pkgs, ... }:

{
  # Bootloader Configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Nix Package Manager & Experimental Features
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    cores = 0;
    max-jobs = "auto";
  };

  # Automatic Garbage Collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Time Zone & Localization
  time.timeZone = "Asia/Tokyo";

  # Headless Server Optimizations (Disable GUI, sound, printing)
  services.xserver.enable = false;
  services.printing.enable = false;
  services.pipewire.enable = false;

  # Primary User Account
  users.users.yano = {
    isNormalUser = true;
    description = "Yano";
    extraGroups = [ "wheel" "docker" ];
    packages = with pkgs; [
      tree
    ];
    home = "/home/yano";
    shell = pkgs.bash;
  };

  # Essential System Packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    fish
    nano
    neovim
    gawk
    findutils
    gnused
    diffutils
    perl
    htop
    pkg-config
    git
    usbutils
    gemini-cli
    nmap
    tcpdump
    dnsutils
    zip
    unzip
    python3
    tmux
    gnumake
    zlib
    ffmpeg
    v4l-utils
    docker_29
    ccache
    zstd
  ];
}
