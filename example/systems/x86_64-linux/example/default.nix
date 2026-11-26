{ pkgs, inputs, ... }:
{
  imports = [
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

  system.stateVersion = "26.11";
}
