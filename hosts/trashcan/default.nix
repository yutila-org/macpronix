{ config, pkgs, pkgs-unstable, ... }:

{
  # ==========================================
  # UNIVERSAL MAC PRO 6,1 OS LAYER
  # ==========================================

  # 1. PERMISSIONS
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "broadcom-sta-6.30.223.271-59-6.12.67"
  ];

  # 2. VIRTUALISATION
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  # [SEC] Advanced Security Posture
  security.apparmor.enable = true;
  security.auditd.enable = true;
  security.audit.enable = true;
  security.pam.sshAgentAuth.enable = true;

  # [SEC] Kernel Hardening
  boot.kernel.sysctl = {
    "kernel.unprivileged_bpf_disabled" = 1;
    "kernel.dmesg_restrict" = 1;
  };

  # 3. SYSTEM ARCHITECTURE
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  services.mbpfan.enable = true;

  # 4. NETWORKING (Broadcom Compatibility Mode)
  networking.hostName = "trashcan";
  networking.networkmanager = {
    enable = true;
    wifi.backend = "wpa_supplicant"; 
    wifi.powersave = false;
  };
  
  # Disable iwd to prevent race conditions for the card
  networking.wireless.iwd.enable = false;
  services.tailscale = {
    enable = true;
    package = pkgs-unstable.tailscale;
  };

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" "docker0" ];
    # [SEC] Zero-Trust: SSH is only accessible via Tailscale VPN
    # allowedTCPPorts = [ 22 ]; 
  };

  # [SEC] Defense-in-Depth
  services.fail2ban.enable = true;

  # [SEC] Hardened SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # 5. MAINTENANCE
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # [SEC] Automated Upgrades (Upstream Flake Lock Updates)
  systemd.timers.macpronix-upgrade = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  systemd.services.macpronix-upgrade = {
    script = ''
      # macpronix is in the system path, execute upgrade as the admin user
      cd /home/admin/macpronix
      /run/current-system/sw/bin/macpronix upgrade
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "admin";
    };
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    git htop btop pciutils lm_sensors fastfetch neovim gnumake
    (pkgs.writeShellScriptBin "macpronix" (builtins.readFile ../../bin/macpronix))
  ];

  environment.variables.EDITOR = "nvim";
  environment.variables.VISUAL = "nvim";
  environment.shellAliases = { vim = "nvim"; vi = "nvim"; };

  # 6. IDENTITY
  users.users.admin = {
    isNormalUser = true;
    description = "Node Admin";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    
    openssh.authorizedKeys.keys = let
      keyFile = ./admin.keys;
    in
      if builtins.pathExists keyFile
      then [ (builtins.readFile keyFile) ]
      else [];
  };

  time.timeZone = "UTC"; 
  i18n.defaultLocale = "en_US.UTF-8";
  system.stateVersion = "24.11";
}