{ config, pkgs, lib, ... }:

with lib;

{
  options.proxmoxLXC = {
    enable = mkOption {
      default = true;
      type = types.bool;
      description = lib.mdDoc "Whether to enable the Proxmox VE LXC module.";
    };
    privileged = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable privileged mounts
      '';
    };
    manageNetwork = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to manage network interfaces through nix options
        When false, systemd-networkd is enabled to accept network
        configuration from proxmox.
      '';
    };
    manageHostName = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to manage hostname through nix options
        When false, the hostname is picked up from /etc/hostname
        populated by proxmox.
      '';
    };
  };

  config =
    let
      cfg = config.proxmoxLXC;
    in
    mkIf cfg.enable {
      system.build.tarball = pkgs.callPackage ../../lib/make-system-tarball.nix {
        storeContents = [{
          object = config.system.build.toplevel;
          symlink = "none";
        }];

        contents = [{
          source = config.system.build.toplevel + "/init";
          target = "/sbin/init";
        }];

        extraCommands = "mkdir -p root etc/systemd/network";
      };

      boot = {
        isContainer = true;
        loader.initScript.enable = true;
      };

      networking = mkIf (!cfg.manageNetwork) {
        useDHCP = false;
        useHostResolvConf = false;
        useNetworkd = true;
        # pick up hostname from /etc/hostname generated by proxmox
        hostName = mkIf (!cfg.manageHostName) (mkForce "");
      };

      services.openssh = {
        enable = mkDefault true;
        startWhenNeeded = mkDefault true;
      };

      systemd.mounts = mkIf (!cfg.privileged)
        [{ where = "/sys/kernel/debug"; enable = false; }];

    };
}
