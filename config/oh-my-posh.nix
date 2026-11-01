{ lib, ... }:
let
  # nf-md-lambda
  # lambda = "";
  lambda = "󰘧";

  # Icons matching the powerlevel10k nerdfont-v3 defaults
  homeIcon = ""; # nf-fa-home
  homeSubIcon = ""; # nf-fa-folder_open
  folderIcon = ""; # nf-fa-folder_open_o
  branchIcon = ""; # nf-fa-code_fork
  projectIcon = ""; # nf-oct-package
  nixIcon = ""; # nf-linux-nixos

  # Well-known folders in ~, shown as "<icon> <name>" via mapped_locations.
  # Icons match yazi's default theme ([icon] dirs)
  # See: https://ohmyposh.dev/docs/segments/system/path#mapped-locations
  homeFolders = {
    Desktop = ""; # U+F108
    Documents = ""; # U+F401
    Downloads = ""; # U+F498
    Music = ""; # U+F025
    Pictures = ""; # U+E244
    Videos = ""; # U+F447
  };
  # Template condition: current dir is one of homeFolders or below it
  inHomeFolder = "(or ${
    lib.concatMapStringsSep " " (
      name:
      "(eq .Location (printf \"%s/${name}\" .Env.HOME)) (hasPrefix (printf \"%s/${name}/\" .Env.HOME) .Location)"
    ) (lib.attrNames homeFolders)
  })";
  # Template condition: current dir is inside a git repo (other than a ~ dotfiles repo).
  # Reads the git segment's properties, see:
  # https://ohmyposh.dev/docs/configuration/templates#cross-segment-template-properties
  inRepo = "(and (.Segments.Contains \"Git\") (ne .Segments.Git.Dir .Env.HOME))";

  # Language version segments, shown in dirs containing matching files.
  # Icons from the oh-my-posh docs samples.
  # See: https://ohmyposh.dev/docs/segments/languages/clojure
  languages = {
    clojure = ""; # U+E768
    crystal = ""; # U+E62F
    dart = ""; # U+E798
    dotnet = ""; # U+E77F
    elixir = ""; # U+E62D
    fortran = "󱈚"; # U+F121A
    go = ""; # U+E627
    haskell = ""; # U+E61F
    java = ""; # U+E738
    julia = ""; # U+E624
    kotlin = ""; # U+E634
    lua = ""; # U+E620
    mojo = "󰈸"; # U+F0238 nf-md-fire, the docs use an emoji
    nim = ""; # U+E841
    node = ""; # U+E718
    ocaml = ""; # U+E67A
    perl = ""; # U+E769
    php = ""; # U+E73D
    python = ""; # U+E235
    r = ""; # U+E68A
    ruby = ""; # U+E791
    rust = ""; # U+E7A8
    swift = ""; # U+E755
    v = ""; # U+E6AC
    vala = ""; # U+E69E
    zig = ""; # U+E6A9
  };
  # Segments that also expose the active virtual environment (.Venv)
  venvLanguages = [
    "python"
    "mojo"
  ];
  languageSegments = lib.mapAttrsToList (
    type: icon:
    let
      hasVenv = lib.elem type venvLanguages;
    in
    {
      inherit type;
      style = "plain";
      foreground = "yellow";
      template = " ${icon} {{ if .Error }}{{ .Error }}{{ else }}${lib.optionalString hasVenv "{{ if .Venv }}{{ .Venv }} {{ end }}"}{{ .Full }}{{ end }}";
      # Show in projects too, not only inside an active venv (the default)
      options = lib.optionalAttrs hasVenv { display_mode = "context"; };
    }
  ) languages;

  # Color the lambda by the exit code of the last command
  lambdaSegment = {
    foreground = "green";
    foreground_templates = [ "{{ if gt .Code 0 }}red{{ end }}" ];
    template = "${lambda} ";
  };
in
{
  prompts.oh-my-posh.settings = {
    "$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json";
    version = 3;
    final_space = false;
    blocks = [
      {
        type = "prompt";
        alignment = "left";
        segments = [
          {
            type = "path";
            style = "plain";
            foreground = "blue";
            # Mapped home folders bring their own icon (unless in a repo). Otherwise:
            # home icon in ~, open folder icon below ~, folder icon elsewhere.
            # In a repo, show the repo name and the path within it.
            template = "{{ if and (not ${inRepo}) ${inHomeFolder} }}{{ else if eq .Location .Env.HOME }}${homeIcon} {{ else if hasPrefix (printf \"%s/\" .Env.HOME) .Location }}${homeSubIcon} {{ else }}${folderIcon} {{ end }}{{ if ${inRepo} }}{{ .Segments.Git.RepoName }}{{ if .Segments.Git.RelativeDir }}/{{ .Segments.Git.RelativeDir }}{{ end }}{{ else }}{{ .Path }}{{ end }}";
            options = {
              style = "full";
              mapped_locations = lib.mapAttrs' (
                name: icon: lib.nameValuePair "~/${name}" "${icon} ${name}"
              ) homeFolders;
            };
          }
          {
            type = "git";
            style = "plain";
            foreground = "magenta";
            template = " {{ if .UpstreamIcon }}{{ .UpstreamIcon }} {{ end }}{{ .HEAD }}{{ if or (gt .Behind 0) (gt .Ahead 0) }} {{ if gt .Behind 0 }}⇣{{ .Behind }}{{ end }}{{ if gt .Ahead 0 }}⇡{{ .Ahead }}{{ end }}{{ end }}{{ if .Working.Changed }} {{ .Working.String }}{{ end }}{{ if .Staging.Changed }} {{ .Staging.String }}{{ end }}";

            options = {
              fetch_status = true;
              # Needed for .UpstreamIcon in omp < 31
              fetch_upstream_icon = true;
              branch_icon = "${branchIcon} ";
              # Remote platform icons, shown via .UpstreamIcon
              github_icon = ""; # nf-fa-github
              gitlab_icon = ""; # nf-fa-gitlab
              bitbucket_icon = ""; # nf-fa-bitbucket
              codeberg_icon = ""; # nf-linux-codeberg
              azure_devops_icon = ""; # nf-cod-azure_devops
              git_icon = ""; # nf-fa-git
            };
          }
          # {
          #   # Name and version from package.json, Cargo.toml, pyproject.toml, ...
          #   type = "project";
          #   style = "plain";
          #   foreground = "yellow";
          #   template = "{{ if .Error }} {{ .Error }}{{ else if or .Name .Version }} ${projectIcon}{{ if .Name }} {{ .Name }}{{ end }}{{ if .Version }} {{ .Version }}{{ end }}{{ end }}";
          # }
        ]
        ++ languageSegments
        ++ [
          {
            # nix-shell / nix develop / direnv (IN_NIX_SHELL). Ignore "unknown", which
            # omp infers from /nix/store in $PATH, as the wrapper always adds those.
            type = "nix-shell";
            style = "plain";
            foreground = "cyan";
            template = "{{ if ne .Type \"unknown\" }} ${nixIcon} nix-shell{{ end }}";
          }
        ];
      }
      {
        type = "prompt";
        alignment = "left";
        newline = true;
        segments = [
          (lambdaSegment // { type = "text"; style = "plain"; })
        ];
      }
    ];
    # Previous prompts collapse to just the lambda
    # See: https://ohmyposh.dev/docs/configuration/transient
    transient_prompt = lambdaSegment;
  };
}
