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
  };


  # networking.hostName = "nixos"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  # Don't use NetworkManager!!!!!
  networking.networkmanager.enable = false;

  # Set your time zone.
  # I live in Japan
  time.timeZone = "Asia/Tokyo";


  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Headless Server Settings (No GUI / No Sound)
  services.xserver.enable = false;
  services.printing.enable = false;
  services.pipewire.enable = false;

  # User configuration
  users.users.yano = {
    isNormalUser = true;
    description = "Yano";
    extraGroups = [ "wheel" ];
    packages = with pkgs; [
      tree
    ];
    home = "/home/yano";
    shell = pkgs.bash;
  };

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim 
    wget
    fish
    nano
    neovim

    htop

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
    #docker-compose
    
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # my firewall settings
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 2049 4000 4001 4002 8189 8000 8001 8889 8888 8554 3000 8080 ];
    allowedUDPPorts = [ 53 67 68 2049 4000 4001 4002 8889 8888 8554 ];
    checkReversePath = false;
    allowPing = true;
  };


  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?

}
