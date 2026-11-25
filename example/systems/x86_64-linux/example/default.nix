{ pkgs, inputs, ... }:
{
  # satisfies assertions; build-vm overrides both via qemu-vm.nix
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  imports = [
    inputs.disko.nixosModules.disko
    ./disko.nix
  ];
  boot.loader.grub.devices = [ "nodev" ];

  networking.hostName = "nixos";
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialHashedPassword = "";
  };
  services.getty.autologinUser = "nixos";
  security.sudo.wheelNeedsPassword = false;
  environment.systemPackages = [
    pkgs.vim
    pkgs.git
  ];
  services.openssh.enable = true;

  system.stateVersion = "26.05";
}
