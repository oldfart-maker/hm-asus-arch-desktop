{ pkgs, repoPath, ... }:

let
  quteWrapped = pkgs.writeShellScriptBin "qutebrowser" ''
    # Force Qt to use Wayland, not X11
    export QT_QPA_PLATFORM=wayland
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

    # Run the Nix qutebrowser through nixGL so it sees the host GPU drivers
    exec nixGL ${pkgs.qutebrowser}/bin/qutebrowser "$@"
  '';

  cfgPath  = repoPath "home/data/apps/qutebrowser/config.py";
  themePath = repoPath "home/data/apps/qutebrowser/gruvbox.py";
  quickMarksPath = repoPath "home/data/apps/qutebrowser/quickmarks";

  # pdf.js install for to view pdf's in qutebrowser natively
  pdfjs = pkgs.fetchzip {
    url       = "https://github.com/mozilla/pdf.js/releases/download/v4.2.67/pdfjs-4.2.67-dist.zip";
    hash      = "sha256-7kfT3+ZwoGqZ5OwkO9h3DIuBFd0v8fRlcufxoBdcy8c=";
    stripRoot = false;
  };  
  
in {  
  programs.qutebrowser = {
    enable = true;
    package=quteWrapped;
    extraConfig = builtins.readFile cfgPath;
  };

  home.file.".config/qutebrowser/gruvbox.py".source    = themePath;
  home.file.".config/qutebrowser/quickmarks".source    = quickMarksPath;  

  xdg.dataFile."qutebrowser/pdfjs".source = pdfjs;

   # This is the .desktop entry
  xdg.desktopEntries.qutebrowser-wayland = {
    name = "Qutebrowser (Wayland + nixGL)";
    genericName = "Web Browser";
    comment = "Keyboard-focused browser using Wayland and nixGL";
    exec = "${quteWrapped}/bin/qutebrowser %u";
    icon = "org.qutebrowser.qutebrowser";
    terminal = false;
    categories = [ "Network" "WebBrowser" ];
    mimeType = [
      "text/html"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
    startupNotify = true;
  };  
}
