#  Snowball

## What it is
Snowball is a framework for NixOS configurations. It is highly inspired by the work of [Jake Hamilton's](https://github.com/jakehamilton) [snowfall-lib](https://github.com/snowfallorg/lib/tree/main).

## How to use?

### Flake setup
You simply create flake with snowball as input:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.11";
    snowball.url = "github:Svenum/snowball";
  };

  outputs =
    inputs:
    inputs.snowball.lib.mkFlake {
      inherit inputs;
      root = ./.;

      # Properties for all systems
      allSystemes = {
        # Additional modules
        modules = [];

        # Additional specialArgs
        specialArgs = {};
      };

      # Properties for a single system
      your_system = {
        # Additional modules
        modules = [];

        # Additional specialArgs
        specialArgs = {};
      };
    };
}

```

Your file structure should look like this:
```bash
your_repo
  |-flake.nix
  |-systems/
  |   |-x86_64-linux/
  |   |   |-your_system/
  |   |       |-default.nix
  |   |-aarch64-linux/
  |       |-your_other_system/
  |           |-default.nix
  |-modules/
  |   |-home/
  |   |   |-module1/
  |   |   |   |-default.nix
  |   |   |-module2/
  |   |       |-default.nix
  |   |-nixos/
  |   |   |-module1/
  |   |   |   |-default.nix
  |   |   |-module2/
  |   |       |-default.nix
  |-overlays/
      |-overlay1/
      |   |-default.nix
      |-overlay2/
      |   |-default.nix
```

### Components
#### Systems
Every directory under `<root>/systems/<system_architecture>/<system_name>/` becomes a `nixosConfiguration`.
Therefor, it is **important** that every `<system_name>` is unique even across architecture types.
As snowball uses the mechanism that an imported directory (e.g. `import ./some_dir`) automatically searches for a `default.nix`
this directory has to contain such a `default.nix` as starting point for your system config.

The structure of the `default.nix` should look like this:
```nix
{config, pkgs, inputs, ...}:
{
  ...
}
```

#### Modules
Snowball automatically creates `nixosModules` for every directory under `<root>/modules/nixos/<module_name>/`.
The same way are `homeModules` computed from `<root>/modules/home/<module_name>/`.

These modules are automatically employed by every system defined.

The structure of the `default.nix` should look like this:
```nix
{config, pkgs, inputs, ...}:
{
  ...
}
```

#### Overlays
Overlays should be stored under `<root>/overlays/<overlay_name>/`.
They are automatically applied to every system known to snowball.

The structure of the `default.nix` should look like this:
```nix
{inputs, ...}:

final: prev: {
  ...
}
```

## Why should I use snowball?
Snowball is a small helper library with no inputs at all.
It uses your already defined `nixpkgs` and will add no overhead that way.
