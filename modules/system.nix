{ config, lib, pkgs, ... }:

{
  # Bootloader Configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Nix Package Manager & Cache Optimizations
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true; # Hard-link identical store files
    cores = 0;
    max-jobs = "auto";
    
    # Binary Caches (Substituters) for faster package downloads
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];

    # Retain build derivations for faster incremental builds
    keep-outputs = true;
    keep-derivations = true;
  };

  # Automatic Garbage Collection (Keep last 7 days of build derivations)
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Global ccache support
  programs.ccache = {
    enable = true;
    cacheDir = "/var/cache/ccache";
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
