options:

let
  inherit (options) inputs;
  nixpkgs = inputs.nixpkgs;
  lib = nixpkgs.lib;

  inherit (builtins)
    pathExists
    readDir
    attrNames
    attrValues
    foldl'
    hasAttr
    concatLists
    ;

  inherit (lib) optionals genAttrs optionalAttrs;
  inherit (options) root;

  # Default paths for systems, homeModules, nixosModules and overlays
  systemsPath = root + "/systems";
  nixosModulesPath = root + "/modules/nixos";
  homeModulesPath = root + "/modules/home";
  overlaysPath = root + "/overlays";

  # Additional modules for each system
  allSystems = if (hasAttr "allSystems" options) then options.allSystems else { };

  overlays = map (overlay: (import overlay { inherit inputs; })) (
    concatLists (attrValues inputs.self.overlays)
  );

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
              inherit (inputs) self;
            }
            // optionalAttrs (hasAttr "specialArgs" allSystems) allSystems.specialArgs
            // optionalAttrs (hasAttr "specialArgs" systemOptions) systemOptions.specialArgs;
            modules = [
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
in
{
  inherit inputs;
  inherit (inputs) self;
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
  overlays = dirToModules overlaysPath;
}
