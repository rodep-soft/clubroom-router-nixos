{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.wifi-as-wan;
in {
  options.services.wifi-as-wan = {
    enable = mkEnableOption "WiFi as WAN router functionality";

    externalInterface = mkOption {
      type = types.str;
      default = "wlan0";
      description = "The upstream WiFi interface connected to the internet (e.g., wlan0).";
    };

    internalInterface = mkOption {
      type = types.str;
      default = "enp2s0";
      description = "The downstream Ethernet interface to serve LAN clients (e.g., enp2s0).";
    };

    internalIp = mkOption {
      type = types.str;
      default = "192.168.50.1";
      description = "The IP address of the internal interface.";
    };

    internalPrefixLength = mkOption {
      type = types.int;
      default = 24;
      description = "The subnet prefix length for the internal interface.";
    };
    
    dhcpRange = mkOption {
      type = types.str;
      default = "192.168.50.100,192.168.50.200,255.255.255.0,12h";
      description = "DHCP range configuration for dnsmasq.";
    };
    
    upstreamDns = mkOption {
      type = types.listOf types.str;
      default = [ "1.1.1.1" "8.8.8.8" ];
      description = "Upstream DNS servers.";
    };

    autoDisableConflicts = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Automatically forcefully disable conflicting services like NetworkManager 
        and systemd-resolved using mkForce. If false, the module will throw an 
        error (assertion) if conflicts are detected, requiring manual intervention.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.autoDisableConflicts || !config.networking.networkmanager.enable;
        message = ''
          The wifi-as-wan module conflicts with NetworkManager. 
          Please explicitly disable NetworkManager in your configuration.nix:
            networking.networkmanager.enable = false;
          OR enable autoDisableConflicts in this module:
            services.wifi-as-wan.autoDisableConflicts = true;
        '';
      }
    ];

    # Disable NetworkManager. If autoDisableConflicts is true, we force it.
    networking.networkmanager.enable = if cfg.autoDisableConflicts then mkForce false else mkDefault false;

    # Pro Router Kernel modules (BBR + CAKE AQM)
    boot.kernelModules = [ "tcp_bbr" "sch_cake" ];
    
    boot.kernel.sysctl = {
      # IPv4 / IPv6 Forwarding
      "net.ipv4.ip_forward" = mkDefault 1;
      "net.ipv6.conf.all.forwarding" = mkDefault 1;
      "net.ipv6.conf.default.forwarding" = mkDefault 1;
      
      # Pro Router AQM & TCP Settings
      # CAKE is specifically designed to eliminate bufferbloat on home routers
      "net.core.default_qdisc" = mkDefault "cake";
      "net.ipv4.tcp_congestion_control" = mkDefault "bbr";

      # Kernel Hardening & Router Security
      # Strict Reverse Path filtering (prevents IP spoofing)
      "net.ipv4.conf.all.rp_filter" = mkDefault 1;
      "net.ipv4.conf.default.rp_filter" = mkDefault 1;
      
      # Ignore ICMP redirects (prevents routing table manipulation)
      "net.ipv4.conf.all.accept_redirects" = mkDefault 0;
      "net.ipv4.conf.default.accept_redirects" = mkDefault 0;
      "net.ipv4.conf.all.secure_redirects" = mkDefault 0;
      "net.ipv4.conf.default.secure_redirects" = mkDefault 0;
      "net.ipv4.conf.all.send_redirects" = mkDefault 0;
      "net.ipv4.conf.default.send_redirects" = mkDefault 0;
      
      # Protect against SYN floods and TIME-WAIT assassination
      "net.ipv4.tcp_syncookies" = mkDefault 1;
      "net.ipv4.tcp_rfc1337" = mkDefault 1;
      
      # Ignore bogus ICMP errors and broadcast pings
      "net.ipv4.icmp_ignore_bogus_error_responses" = mkDefault 1;
      "net.ipv4.icmp_echo_ignore_broadcasts" = mkDefault 1;
      
      # Log Martian packets (spoofed/impossible IP addresses)
      "net.ipv4.conf.all.log_martians" = mkDefault 1;
      "net.ipv4.conf.default.log_martians" = mkDefault 1;

      # Memory & Swap tweaks
      "vm.swappiness" = mkDefault 100;
      "vm.watermark_boost_factor" = mkDefault 0;
      "vm.watermark_scale_factor" = mkDefault 125;
      "vm.page-cluster" = mkDefault 0;
    };

    # Modern Firewall (nftables instead of legacy iptables)
    networking.nftables.enable = mkDefault true;

    # iwd for upstream WiFi management
    networking.wireless.iwd.enable = mkDefault true;
    networking.wireless.iwd.settings = mkDefault {
      Network = {
        EnableIPv6 = true;
      };
      Settings = {
        AutoConnect = true;
      };
    };

    # systemd-networkd for interface management
    systemd.network.enable = mkDefault true;

    # Use local dnsmasq for resolution. Force disable if requested.
    services.resolved.enable = if cfg.autoDisableConflicts then mkForce false else mkDefault false;
    networking.resolvconf.enable = if cfg.autoDisableConflicts then mkForce false else mkDefault false;
    
    # We only set this if resolvconf is disabled by us
    environment.etc."resolv.conf".text = mkIf (config.networking.resolvconf.enable == false) (mkDefault ''
      nameserver 127.0.0.1
    '');

    # Internal interface static IP configuration
    systemd.network.networks."10-lan" = {
      matchConfig.Name = cfg.internalInterface;
      address = [ "${cfg.internalIp}/${toString cfg.internalPrefixLength}" ];
      networkConfig = {
        DHCP = mkDefault "no";
        ConfigureWithoutCarrier = mkDefault "yes";
      };
    };

    # NAT setup
    networking.nat = {
      enable = mkDefault true;
      externalInterface = mkDefault cfg.externalInterface;
      internalInterfaces = [ cfg.internalInterface ];
    };

    # DHCP and DNS server (dnsmasq)
    services.dnsmasq = {
      enable = mkDefault true;
      settings = {
        interface = mkDefault cfg.internalInterface;
        bind-interfaces = mkDefault true;
        listen-address = mkDefault "127.0.0.1,${cfg.internalIp}";
        dhcp-authoritative = mkDefault true;
        dhcp-range = mkDefault cfg.dhcpRange;
        dhcp-option = [
          "option:router,${cfg.internalIp}"
          "option:dns-server,${cfg.internalIp}"
        ];
        server = mkDefault cfg.upstreamDns;
        no-resolv = mkDefault true;
        cache-size = mkDefault 1000;
        
        # Pro DNS Security settings
        domain-needed = mkDefault true; # Don't forward short names (e.g., 'localhost')
        bogus-priv = mkDefault true;    # Don't forward reverse lookups for local IPs
        stop-dns-rebind = mkDefault true; # Prevent DNS rebinding attacks
        rebind-localhost-ok = mkDefault true;
        
        # Local domain configuration
        domain = mkDefault "lan";
        local = mkDefault "/lan/";
        expand-hosts = mkDefault true;
      };
      resolveLocalQueries = mkDefault false;
    };

    # Allow DHCP and DNS traffic from the internal network
    # NixOS automatically merges these lists.
    networking.firewall.allowedUDPPorts = [ 53 67 68 ];
    networking.firewall.allowedTCPPorts = [ 53 ];
  };
}
