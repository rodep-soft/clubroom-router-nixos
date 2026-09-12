.PHONY: switch test boot update cp

# Apply NixOS Flake configuration directly
switch:
	sudo nixos-rebuild switch --flake .#nixos

# Test configuration without adding to bootloader
test:
	sudo nixos-rebuild test --flake .#nixos

# Build and set as boot default (activate on reboot)
boot:
	sudo nixos-rebuild boot --flake .#nixos

# Update flake.lock dependencies
update:
	nix flake update

# Legacy copy to /etc/nixos
cp:
	sudo cp -r * /etc/nixos/
