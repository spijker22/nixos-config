# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;
#zram
zramSwap = {
  enable = true;
  algorithm = "zstd";    # good compression + fast (default)
  memoryPercent = 50;    # max 50% of RAM (default)
  priority = 100;        # higher than disk swap so it's preferred
};
  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  #older than 30 day generations
nix.gc.automatic = true;
nix.gc.options = "--delete-older-than 30d";   

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
services.tailscale.enable = true;
  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "nl_NL.UTF-8";
    LC_IDENTIFICATION = "nl_NL.UTF-8";
    LC_MEASUREMENT = "nl_NL.UTF-8";
    LC_MONETARY = "nl_NL.UTF-8";
    LC_NAME = "nl_NL.UTF-8";
    LC_NUMERIC = "nl_NL.UTF-8";
    LC_PAPER = "nl_NL.UTF-8";
    LC_TELEPHONE = "nl_NL.UTF-8";
    LC_TIME = "nl_NL.UTF-8";
  };

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
#dconf
  programs.dconf.profiles.user.databases = [
    {
      lockAll = true; # prevents overriding
      settings = {
        "org/gnome/desktop/interface" = {
          accent-color = "blue";
        };
        "org/gnome/desktop/input-sources" = {
          xkb-options = [ "ctrl:nocaps" ];
        };
      };
    }
  ];

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."luuk" = {
    isNormalUser = true;
    description = "luuk";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  # environment.systemPackages = with pkgs; [
  #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #   wget
  # ];

#firewall
networking.firewall.enable = true;

#packages extra
environment.systemPackages = with pkgs; [
  brave
 #librewolf
  samba
  transmission_4
  htop
  fastfetch
  gimp
  cmatrix
  android-tools
  supertuxkart
  tor-browser
  vlc
  git
  libreoffice
  signal-desktop
  aisleriot
  fish
];
#alias
programs.bash.shellInit = ''
  deploy() {
    local msg=update
    [ -n "$1" ] && msg="$1"
    sudo nixos-rebuild switch &&
    cd ~/.config/nixos &&
    git add . &&
    git commit -m "$msg" &&
    git push
  }
'';   
#cloudflare dns 
#networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];
#networking.networkmanager.dns = "none";   
#unbound 
services.unbound = {
  enable = true;
  settings.server = {
    interface = [ "192.168.2.2" "127.0.0.1" ];
    access-control = [ "192.168.2.0/24 allow" ];
    module-config = "'respip validator iterator'";
  };
  settings.rpz = [{
    name = "hageziPro";
    url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/rpz/pro.txt";
  }];
  settings.forward-zone = [{
    name = ".";
    forward-tls-upstream = true;
    forward-addr = [
      "9.9.9.9@853#dns.quad9.net"
      "149.112.112.112@853#dns.quad9.net"
      "1.1.1.1@853#cloudflare-dns.com"
      "1.0.0.1@853#cloudflare-dns.com"
    ];
  }];
};   
#flatpak
services.flatpak.enable = true;

systemd.services.flatpak-management = {
  description = "Manage Flatpak installations";
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = "yes";
    ExecStart = pkgs.writeScript "flatpak-management" ''
      #!${pkgs.runtimeShell} -e
      ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub \
        https://flathub.org/repo/flathub.flatpakrepo

      for app in com.google.Chrome org.mozilla.firefox; do
        ${pkgs.flatpak}/bin/flatpak install -y --noninteractive flathub "$app"
      done

      ${pkgs.flatpak}/bin/flatpak update -y --noninteractive
    '';
  };
  wantedBy = [ "multi-user.target" ];
};

systemd.timers.flatpak-management = {
  description = "Daily Flatpak management";
  timerConfig = {
    OnCalendar = "daily";
    Persistent = true;
  };
  wantedBy = [ "timers.target" ];
};   

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}
