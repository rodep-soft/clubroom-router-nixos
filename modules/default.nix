{ config, lib, pkgs, ... }:

{
  imports = [
    ./wifi-as-wan.nix
    ./performance.nix
    ./router.nix
    ./proxy.nix
    ./monitoring.nix
    ./services.nix
    ./runner.nix
    ./system.nix
  ];
}
