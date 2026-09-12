{ config, lib, pkgs, ... }:

{
  # ==========================================
  # Caddy Reverse Proxy for Local Domains (*.lan)
  # ==========================================
  services.caddy = {
    enable = true;

    virtualHosts = {
      # Router Default Landing / Shortcut
      "http://router.lan" = {
        extraConfig = ''
          redir http://nas.lan{uri}
        '';
      };

      # AdGuard Home Web UI (DNS Management & Ad Blocking)
      "http://adguard.lan" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:3000
        '';
      };
      "http://dns.lan" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:3000
        '';
      };

      # FileBrowser (Web NAS / Data Manager)
      "http://nas.lan" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:8080
        '';
      };
      "http://drive.lan" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:8080
        '';
      };
      "http://files.lan" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:8080
        '';
      };

      # Grafana Metrics & System Monitoring Dashboard
      "http://grafana.lan" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:3100
        '';
      };
      "http://monitor.lan" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:3100
        '';
      };
      "http://status.lan" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:3100
        '';
      };

      # Distcc Web Status Monitor
      "http://distcc.lan" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:3633
        '';
      };

      # Tailscale / Hostname / Default HTTP Catch-All
      # Accessing via Tailscale IP (http://100.x.y.z) or hostname (http://nixos)
      # directly opens FileBrowser NAS on standard port 80
      ":80" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:8080
        '';
      };
    };
  };

  # Open HTTP (80) and HTTPS (443) on the firewall
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
