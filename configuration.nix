# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./wifi-as-wan.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # ==========================================
  # High-Performance Kernel & Sysctl Tuning
  # ==========================================
  boot.kernelParams = [
    "cpufreq.default_governor=performance"
    "intel_pstate=active"
    "mitigations=off"
    "tsc=reliable"
    "clocksource=tsc"
    "nowatchdog"
  ];

  boot.kernel.sysctl = {
    # Network: BBR + CAKE for low-latency & high-throughput router
    "net.core.default_qdisc" = "cake";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.netdev_max_backlog" = 16384;
    "net.core.somaxconn" = 8192;
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 87380 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.tcp_tw_reuse" = 1;

    # Memory & Disk I/O Performance
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 10;
    "fs.file-max" = 2097152;
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 8192;
  };

  # RAM disk for /tmp to speed up builds and reduce SSD wear
  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "16G";
  };

  # Mount root with noatime for reduced disk writes
  fileSystems."/".options = [ "noatime" "nodiratime" ];

  powerManagement.cpuFreqGovernor = "performance";

  nix.settings.auto-optimise-store = true; 

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d"; 
  };

  nix.settings.cores = 0;
  nix.settings.max-jobs = "auto";

  zramSwap.enable = true;

  # ==========================================
  # WiFi as WAN Router Module
  # ==========================================
  services.wifi-as-wan = {
    enable = true;
    externalInterface = "wlan0";
    internalInterface = "enp2s0";
    internalIp = "192.168.50.1";
    upstreamDns = [ "127.0.0.1#5335" ];
    autoDisableConflicts = true;
  };
  # ==========================================

  # ==========================================
  # AdGuard Home (DNS Ad Blocking & Protection)
  # ==========================================
  services.adguardhome = {
    enable = true;
    port = 3000;
    settings = {
      dns = {
        bind_hosts = [ "127.0.0.1" ];
        port = 5335;
        upstream_dns = [
          "https://dns.quad9.net/dns-query"
          "https://cloudflare-dns.com/dns-query"
        ];
      };
      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
      };
    };
  };
  # ==========================================

  # ==========================================
  # FileBrowser (Web File Manager for /data)
  # ==========================================
  services.filebrowser = {
    enable = true;
    settings = {
      address = "0.0.0.0";
      port = 8080;
      root = "/data";
    };
  };
  # ==========================================

  # vpn
  services.tailscale = {
    enable = true;
    extraUpFlags = [ "--accept-dns=false" ];
  };

  # nas
  services.nfs.server.enable = true;

  services.nfs.server.exports = ''
    /data 192.168.50.0/24(rw,sync,no_subtree_check)
    /data 100.64.0.0/10(rw,sync,no_subtree_check)
  '';

  services.nfs.server.statdPort = 4000;
  services.nfs.server.lockdPort = 4001;
  services.nfs.server.mountdPort = 4002;

  virtualisation.docker = {
    enable = true;
    package = pkgs.docker_29;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  nixpkgs.config.permittedInsecurePackages = [
    "docker-28.5.2"
  ];

  # networking.hostName = "nixos"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  # Don't use NetworkManager!!!!!
  networking.networkmanager.enable = false;

  # Set your time zone.
  # I live in Japan
  time.timeZone = "Asia/Tokyo";

  # Headless Server Settings (No GUI / No Sound)
  services.xserver.enable = false;
  services.printing.enable = false;
  services.pipewire.enable = false;

  # User configuration
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

  # List packages installed in system profile.
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

  # GitHub Actions Self-Hosted Runner (rodep-soft)
  services.github-runners.rodep-builder = {
    enable = true;
    url = "https://github.com/rodep-soft";
    tokenFile = "/var/lib/github-runner/token";
    user = "yano";
    workDir = "/var/lib/github-runner/work";
    replace = true;
    extraPackages = with pkgs; [ docker_29 git ccache zstd coreutils ];
    serviceOverrides = {
      ProtectProc = "default";
      ProcSubset = "all";
      ProtectControlGroups = false;
    };
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # my firewall settings
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 2049 4000 4001 4002 8189 8000 8001 8889 8888 8554 3000 8080 ];
    allowedUDPPorts = [ 53 67 68 2049 4000 4001 4002 8889 8888 8554 ];
    checkReversePath = false;
    allowPing = true;
  };

  system.stateVersion = "25.11";
}
