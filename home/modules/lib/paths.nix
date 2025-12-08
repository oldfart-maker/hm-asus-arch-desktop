{ inputs, config, ... }:
let
  repoPath = rel: inputs.self + "/${rel}";
in {
  # existing helper
  _module.args.repoPath = repoPath;

  # ensure ~/.local/bin is on PATH for this user
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
  ];
}
