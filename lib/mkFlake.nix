options:

let
  inherit (options) inputs;
  inherit (inputs) self nixpkgs;
  lib = nixpkgs.lib;

  inherit (builtins)
    pathExists
    readDir
    attrNames
    attrValues
    foldl'
    hasAttr
    concatLists
    elem
    ;

  inherit (lib)
    optionals
    genAttrs
    optionalAttrs
    recursiveUpdate
    mapAttrsToList
    ;
  inherit (options) root;

  # Default paths for systems, homeModules, nixosModules and overlays
  systemsPath = root + "/systems";
  nixosModulesPath = root + "/modules/nixos";
  homeModulesPath = root + "/modules/home";
  overlaysPath = root + "/overlays";
  packagesPath = root + "/packages";

  # supported systems
  supportedSystems =
    if hasAttr "supportedSystems" options then
      options.supportedSystems
    else
      [
        "x86_64-linux"
        "aarch64-darwin"
        "aarch64-linux"
      ];

  # Additional modules for each system
  allSystems = if (hasAttr "allSystems" options) then options.allSystems else { };

  # This helper function loads the dirs and subdirs
  # of a directory and creates a hosts attribute set
  # e.g.:    /systems/x86_64-linux/example/default.nix
  # becomes:
  # example = {
  #   system = "x86_64-linux";
  #   imports = [ ./systems/x86_64-linux/example ];
  # }
  dirToSystems =
    dir:
    let
      systemTypes = attrNames (readDir dir);
      systems = map (
        systemType:
        assert
          (elem systemType supportedSystems)
          || abort ''
            ${systemType} is not in the list of supported systems (${toString supportedSystems}).
            Please change the name of the directory or add the type to `supportedSystems`.
          '';
        (genAttrs (attrNames (readDir (dir + "/${systemType}"))) (
          system:
          let
            hasSystem = hasAttr "${system}" options;
            systemOptions = if hasSystem then options."${system}" else { };
          in
          lib.nixosSystem {
            system = systemType;
            specialArgs = {
              inherit inputs;
              inherit self;
            }
            // optionalAttrs (hasAttr "specialArgs" allSystems) allSystems.specialArgs
            // optionalAttrs (hasAttr "specialArgs" systemOptions) systemOptions.specialArgs;
            modules =
              let
                overlays = mapAttrsToList (name: value: value) self.overlays;
              in
              [
                (dir + "/${systemType}/${system}")
                (_: { nixpkgs = { inherit overlays; }; })
              ]
              ++ optionals (hasAttr "modules" allSystems) allSystems.modules
              ++ optionals (hasAttr "modules" systemOptions) systemOptions.modules;
          }
        ))
      ) systemTypes;
    in
    foldl' (setOfSystems: system: setOfSystems // system) { } systems;

  # This helper function loads the dirs and all its
  # subdirs of a directory and creates a module attribute set
  # e.g.:    /modules/example/test/default.nix
  # becomes:
  # example = [ /modules/example/test/default.nix ];
  dirToModules =
    dir:
    let
      modules = attrNames (readDir dir);
      modulesWithSubmodules = map (module: {
        "${module}" = lib.fileset.toList (
          (lib.fileset.fileFilter (file: file.name == "default.nix")) (dir + "/${module}")
        );
      }) modules;
    in
    foldl' (setOfModules: module: setOfModules // module) { } modulesWithSubmodules;

  # This helper function loads the dirs and all its
  # subdirs of a directory and creates a overlay attribute set
  # e.g.:    /overlays/example/default.nix
  # becomes:
  # example = <<lambda @ /overlays/example/default.nix:3:1>>;
  dirToOverlays =
    dir:
    let
      overlayNames = attrNames (readDir dir);
      overlays = map (overlay: {
        "${overlay}" = import (dir + "/${overlay}") {
          inherit inputs;
          inherit self;
        };
      }) overlayNames;
    in
    foldl' (setOfOverlays: overlay: setOfOverlays // overlay) { } overlays;

  # This helper function loads the dirs and all its
  # subdirs of a directory and creates a attribute set
  # of packages for each system in supportedSystems
  # e.g.:    /packages/example/default.nix
  # becomes:
  # {
  #   x86_64-linux.example = pkgs.callPackage /packages/example/default.nix {};
  #   aarch64-linux.example = pkgs.callPackage /packages/example/default.nix {};
  #   aarch64-darwin.example = pkgs.callPackage /packages/example/default.nix {};
  # };
  dirToPackages =
    dir:
    let
      packageNames = attrNames (readDir dir);
      packagesList = map (
        package:
        map (
          system:
          let
            pkgs = import nixpkgs { inherit system; };
          in
          {
            "${system}"."${package}" = pkgs.callPackage (dir + "/${package}") { };
          }
        ) supportedSystems
      ) packageNames;
      packages = lib.lists.flatten packagesList;
    in
    foldl' (setOfOverlays: overlay: recursiveUpdate setOfOverlays overlay) { } packages;
in
{
  inherit inputs;
  inherit self;
}
// optionalAttrs (pathExists systemsPath) {
  nixosConfigurations = dirToSystems systemsPath;
}
// optionalAttrs (pathExists nixosModulesPath) {
  nixosModules = dirToModules nixosModulesPath;
}
// optionalAttrs (pathExists homeModulesPath) {
  homeModules = dirToModules homeModulesPath;
}
// optionalAttrs (pathExists overlaysPath) {
  overlays = dirToOverlays overlaysPath;
}
// optionalAttrs (pathExists packagesPath) {
  packages = dirToPackages packagesPath;
}
