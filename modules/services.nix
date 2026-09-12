{ config, lib, pkgs, ... }:

{
  # Tailscale VPN (with Subnet Router for LAN 192.168.50.0/24)
  services.tailscale = {
    enable = true;
    extraUpFlags = [
      "--accept-dns=false"
      "--advertise-routes=192.168.50.0/24"
    ];
  };

  # NFS NAS Server
  services.nfs.server = {
    enable = true;
    exports = ''
      /data 192.168.50.0/24(rw,sync,no_subtree_check)
      /data 100.64.0.0/10(rw,sync,no_subtree_check)
    '';
    statdPort = 4000;
    lockdPort = 4001;
    mountdPort = 4002;
  };

  # FileBrowser (Web File Manager for /data)
  services.filebrowser = {
    enable = true;
    settings = {
      address = "0.0.0.0";
      port = 8080;
      root = "/data";
    };
  };

  # Docker Container Engine with BuildKit & Cache Optimization
  virtualisation.docker = {
    enable = true;
    package = pkgs.docker_29;
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" "--filter" "until=168h" ];
    };
    daemon.settings = {
      features = {
        buildkit = true;
      };
      # Optimize Docker log size to prevent disk bloat
      "log-driver" = "json-file";
      "log-opts" = {
        "max-size" = "50m";
        "max-file" = "3";
      };
    };
  };

  nixpkgs.config.permittedInsecurePackages = [
    "docker-28.5.2"
  ];

  # Distcc Distributed C/C++ Compiler Daemon
  # Enables team members on LAN or Tailscale to offload GCC/G++ compilation to 16 threads
  services.distccd = {
    enable = true;
    allowedClients = [
      "127.0.0.1"
      "192.168.50.0/24"
      "100.64.0.0/10"
    ];
    stats = {
      enable = true;
      port = 3633;
    };
    zeroconf = true;
  };

  # OpenSSH Server
  services.openssh.enable = true;

  # Distcc Ports (3632 daemon, 3633 web stats)
  networking.firewall.allowedTCPPorts = [ 3632 3633 ];
}
