{ config, lib, pkgs, ... }:

{
  # GitHub Actions Self-Hosted Runner for RoDEP organization
  services.github-runners.rodep-builder = {
    enable = true;
    url = "https://github.com/rodep-soft";
    tokenFile = "/var/lib/github-runner/token";
    user = "yano";
    workDir = "/var/lib/github-runner/work";
    replace = true;
    extraPackages = with pkgs; [
      docker_29
      git
      ccache
      zstd
      coreutils
    ];
    extraEnvironment = {
      CCACHE_DIR = "/home/yano/.cache/ccache";
      CCACHE_MAXSIZE = "50G";
      DOCKER_BUILDKIT = "1";
    };
    serviceOverrides = {
      ProtectProc = "default";
      ProcSubset = "all";
      ProtectControlGroups = false;
    };
  };
}
