{ config, lib, pkgs, ... }:

{
  # ==========================================
  # Node Exporter (Hardware & OS Metrics Collector)
  # ==========================================
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9100;
    enabledCollectors = [
      "systemd"
      "processes"
      "cpufreq"
      "hwmon"
      "diskstats"
      "filesystem"
      "loadavg"
      "meminfo"
      "netdev"
      "netstat"
      "stat"
      "time"
      "uname"
      "vmstat"
    ];
  };

  # ==========================================
  # Prometheus (Metric Storage Engine)
  # ==========================================
  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9090;
    retentionTime = "30d";
    scrapeConfigs = [
      {
        job_name = "node";
        scrape_interval = "10s";
        static_configs = [
          {
            targets = [ "127.0.0.1:9100" ];
            labels = {
              instance = "clubroom-router";
            };
          }
        ];
      }
    ];
  };

  # ==========================================
  # Grafana (Metrics Visualization Dashboard)
  # ==========================================
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3100; # Port 3000 is used by AdGuard Home
        domain = "grafana.lan";
      };
      # Anonymous viewer access for clubroom dashboard
      "auth.anonymous" = {
        enabled = true;
        org_name = "Main Org.";
        org_role = "Viewer";
      };
      security = {
        admin_user = "admin";
      };
    };

    # Automatically configure Prometheus as the default Data Source
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:9090";
          isDefault = true;
          editable = true;
        }
      ];
    };
  };
}
