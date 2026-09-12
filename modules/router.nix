{ config, lib, pkgs, ... }:

{
  # ==========================================
  # WiFi as WAN Router Module Configuration
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
  # AdGuard Home (DNS Ad Blocking & High-Speed DNS Cache)
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
        # High-Speed DNS Cache Settings
        cache_size = 536870912;  # 512 MB RAM cache for instant DNS resolution
        cache_ttl_min = 3600;    # Cache entries for at least 1 hour
        cache_optimistic = true; # Return cached response immediately and refresh in background
      };
      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
      };
    };
  };

  # Disable NetworkManager to prevent interference with router daemons
  networking.networkmanager.enable = false;

  # Firewall Rules
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 2049 4000 4001 4002 8189 8000 8001 8889 8888 8554 3000 8080 ];
    allowedUDPPorts = [ 53 67 68 2049 4000 4001 4002 8889 8888 8554 ];
    checkReversePath = false;
    allowPing = true;
  };
}
