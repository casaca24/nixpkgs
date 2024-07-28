{ lib, stdenv, buildEnv, devShellTools }:

# A special kind of derivation that is only meant to be consumed by the
# nix-shell.
{ name ? "nix-shell"
, # a list of packages to add to the shell environment
  packages ? [ ]
, # propagate all the inputs from the given derivations
  inputsFrom ? [ ]
, buildInputs ? [ ]
, nativeBuildInputs ? [ ]
, propagatedBuildInputs ? [ ]
, propagatedNativeBuildInputs ? [ ]
, passthru ? { }
, ...
}@attrs:
let
  mergeInputs = name:
    (attrs.${name} or [ ]) ++
    # 1. get all `{build,nativeBuild,...}Inputs` from the elements of `inputsFrom`
    # 2. since that is a list of lists, `flatten` that into a regular list
    # 3. filter out of the result everything that's in `inputsFrom` itself
    # this leaves actual dependencies of the derivations in `inputsFrom`, but never the derivations themselves
    (lib.subtractLists inputsFrom (lib.flatten (lib.catAttrs name inputsFrom)));

  rest = builtins.removeAttrs attrs [
    "name"
    "packages"
    "inputsFrom"
    "buildInputs"
    "nativeBuildInputs"
    "propagatedBuildInputs"
    "propagatedNativeBuildInputs"
    "shellHook"
  ];
in

stdenv.mkDerivation (finalAttrs: {
  inherit name;

  buildInputs = mergeInputs "buildInputs";
  nativeBuildInputs = packages ++ (mergeInputs "nativeBuildInputs");
  propagatedBuildInputs = mergeInputs "propagatedBuildInputs";
  propagatedNativeBuildInputs = mergeInputs "propagatedNativeBuildInputs";

  shellHook = lib.concatStringsSep "\n" (lib.catAttrs "shellHook"
    (lib.reverseList inputsFrom ++ [ attrs ]));

  phases = [ "buildPhase" ];

  # TODO: Perhaps mkShell could *be* its own devShell, by setting isDevShell = true;
  buildPhase = ''
    { echo "------------------------------------------------------------";
      echo " WARNING: the existence of this path is not guaranteed.";
      echo " It is an internal implementation detail for pkgs.mkShell.";
      echo "------------------------------------------------------------";
      echo;
      # Record all build inputs as runtime dependencies
      export;
    } >> "$out"
  '';

  preferLocalBuild = true;

  passthru = {
    devShell =
      let
        inherit (finalAttrs.finalPackage) drvAttrs;
      in
      devShellTools.buildShellEnv {
        inherit drvAttrs;

        # The default prefix is "build shell", but this shell is not derived
        # directly from a derivation, so we set a more generic title.
        promptPrefix = "nix";

        # Change the default name
        promptName =
          if
            # name was passed originally
            attrs?name
            # or with overrideAttrs
            || drvAttrs.name != "nix-shell"
          then null
          else "mkShell";
      };
  } // passthru;
} // rest)
