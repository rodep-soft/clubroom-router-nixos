{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules
  ];

  # Hostname
  networking.hostName = "nixos";

  # State version for backward compatibility
  system.stateVersion = "25.11";
}
