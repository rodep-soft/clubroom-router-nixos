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
    serviceOverrides = {
      ProtectProc = "default";
      ProcSubset = "all";
      ProtectControlGroups = false;
    };
  };
}
