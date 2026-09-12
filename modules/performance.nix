{ config, lib, pkgs, ... }:

{
  # High-performance Zen kernel optimized for responsiveness
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # Performance kernel command-line parameters
  boot.kernelParams = [
    "cpufreq.default_governor=performance"
    "intel_pstate=active"
    "mitigations=off"
    "tsc=reliable"
    "clocksource=tsc"
    "nowatchdog"
  ];

  # Network & VM Sysctl tuning
  boot.kernel.sysctl = {
    # Network: BBR congestion control + CAKE queue discipline
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

  # RAM disk for /tmp to accelerate compilation and reduce SSD wear
  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "16G";
  };

  # Reduce disk write overhead
  fileSystems."/".options = [ "noatime" "nodiratime" ];

  # Lock CPU governor to performance
  powerManagement.cpuFreqGovernor = "performance";

  # Compressed RAM swap
  zramSwap.enable = true;
}
