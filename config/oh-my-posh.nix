{ lib, ... }:
let
  # nf-md-lambda
  # lambda = "";
  lambda = "󰘧";

  # Icons matching the powerlevel10k nerdfont-v3 defaults
  homeIcon = ""; # nf-fa-home
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
  # Template condition: current dir is one of homeFolders (or below it, if withSubdirs)
  inHomeFolder =
    withSubdirs:
    let
      conditions = lib.concatMap (
        name:
        [ ''(eq .Location (printf "%s/${name}" .Env.HOME))'' ]
        ++ lib.optional withSubdirs ''(hasPrefix (printf "%s/${name}/" .Env.HOME) .Location)''
      ) (lib.attrNames homeFolders);
    in
    "(or ${lib.concatStringsSep " " conditions})";
  # Template condition: current dir is inside a git repo (other than a ~ dotfiles repo).
  # Reads the git segment's properties, see:
  # https://ohmyposh.dev/docs/configuration/templates#cross-segment-template-properties
  inRepo = ''(and (.Segments.Contains "Git") (ne .Segments.Git.Dir .Env.HOME))'';

  # Responsive prompt: terminal widths (in columns) below which segments collapse or hide.
  # Uses the segments' min_width/max_width, see:
  # https://ohmyposh.dev/docs/configuration/segment
  breakpoints = {
    fullPath = 100; # below: all but the last folder collapse to their first letter
    letterPath = 80; # below: only the last folder
    languages = 70; # below: no language segments
    nixShell = 60; # below: no nix-shell segment
  };

  # Maximum widths of segment texts, in percent of the terminal width. Longer texts
  # are truncated with an ellipsis. The path is truncated as a last resort only,
  # after the breakpoints above already collapsed it.
  maxWidths = {
    path = 40;
    branch = 25;
  };
  # Template expression: percent of the terminal width, at least 8 columns.
  # $OMP_COLUMNS is exported by src/oh-my-posh.zsh, templates can't read the width
  # otherwise. Without it (e.g. omp used outside this wrapper) nothing is truncated.
  widthPercent =
    percent:
    ''(max 8 (div (mul (atoi (default "9999" .Env.OMP_COLUMNS)) ${toString percent}) 100))'';

  # Template expressions for the path text.
  # In a repo, show the repo name and the path within it
  repoPath = ''(trimSuffix "/" (printf "%s/%s" .Segments.Git.RepoName .Segments.Git.RelativeDir))'';
  # repoPath collapsed like the letter style, as .Format doesn't shorten relative paths.
  # Keeps the first letter of each folder but the last (two for hidden folders).
  repoPathLetters = ''(regexReplaceAll "([.]?[^/])[^/]*/" ${repoPath} "$1/")'';
  # The letter style drops the leading / of paths outside ~
  letterPath = ''(printf "%s%s" (ternary "" "/" (or (hasPrefix "/" .Path) (eq .Location .Env.HOME) (hasPrefix (printf "%s/" .Env.HOME) .Location))) .Path)'';

  # Multi-line templates below use {{- and -}}, which trim all whitespace (incl. newlines)
  # before/after the tag. Spaces that are part of the output are written as {{ " " }}
  # where they'd otherwise be trimmed.

  mkPathSegment =
    {
      style,
      path ? ".Path",
      inRepoPath,
      # Whether the mapped icon is still shown below a mapped home folder
      mappedSubdirs ? true,
    }:
    {
      type = "path";
      style = "plain";
      foreground = "blue";
      template = ''
        {{- $path := ${path} -}}
        {{- if ${inRepo} }}{{ $path = ${inRepoPath} }}{{ end -}}
        {{- $max := ${widthPercent maxWidths.path} -}}

        {{- /* Icon. Mapped home folders bring their own (unless in a repo) */ -}}
        {{- if and (not ${inRepo}) ${inHomeFolder mappedSubdirs} -}}
        {{- else if eq .Location .Env.HOME -}}
          ${homeIcon}{{ " " }}
        {{- else if hasPrefix (printf "%s/" .Env.HOME) .Location -}}
          ${homeSubIcon}{{ " " }}
        {{- else -}}
          ${folderIcon}{{ " " }}
        {{- end -}}

        {{- /* Overly long paths keep their end: …/deep/dir. Negative truncE always adds
               the … and fails on shorter texts, hence the length check (in characters,
               not bytes) */ -}}
        {{- if gt (len (splitList "" $path)) (int $max) -}}
          {{ truncE (mul -1 $max) $path }}
        {{- else -}}
          {{ $path }}
        {{- end -}}
      '';
      options = {
        inherit style;
        mapped_locations = lib.mapAttrs' (
          name: icon: lib.nameValuePair "~/${name}" "${icon} ${name}"
        ) homeFolders;
      };
    };

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
  # The venv name is only shown when expanded with Ctrl-e (see src/oh-my-posh.zsh)
  venvTemplate = ''{{- if and .Env.OMP_EXPAND .Venv }}{{ .Venv }} {{ end -}}'';
  languageSegments = lib.mapAttrsToList (
    type: icon:
    let
      hasVenv = lib.elem type venvLanguages;
    in
    {
      inherit type;
      style = "plain";
      foreground = "yellow";
      min_width = breakpoints.languages;
      template = ''
        {{- " " }}${icon}{{ " " -}}
        {{- if .Error -}}
          {{ .Error }}
        {{- else -}}
          ${lib.optionalString hasVenv venvTemplate}
          {{- .Full }}
        {{- end -}}
      '';
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
          # One path segment per width range, only one of them is shown
          (
            mkPathSegment {
              style = "full";
              inRepoPath = repoPath;
            }
            // {
              min_width = breakpoints.fullPath;
            }
          )
          (
            mkPathSegment {
              style = "letter";
              path = letterPath;
              inRepoPath = repoPathLetters;
            }
            // {
              min_width = breakpoints.letterPath;
              max_width = breakpoints.fullPath - 1;
            }
          )
          (
            mkPathSegment {
              style = "folder";
              inRepoPath = ".Path";
              mappedSubdirs = false;
            }
            // {
              max_width = breakpoints.letterPath - 1;
            }
          )
          {
            type = "git";
            style = "plain";
            foreground = "magenta";
            template = ''
              {{- " " -}}
              {{- if .UpstreamIcon }}{{ .UpstreamIcon }} {{ end -}}
              {{- .HEAD -}}
              {{- if or (gt .Behind 0) (gt .Ahead 0) -}}
                {{ " " }}
                {{- if gt .Behind 0 }}⇣{{ .Behind }}{{ end -}}
                {{- if gt .Ahead 0 }}⇡{{ .Ahead }}{{ end -}}
              {{- end -}}
              {{- if .Working.Changed }} {{ .Working.String }}{{ end -}}
              {{- if .Staging.Changed }} {{ .Staging.String }}{{ end -}}
            '';

            options = {
              fetch_status = true;
              # Needed for .UpstreamIcon in omp < 31
              fetch_upstream_icon = true;
              branch_icon = "${branchIcon} ";
              # Truncate long branch names (incl. the trailing …), see maxWidths
              branch_template = "{{ truncE ${widthPercent maxWidths.branch} .Branch }}";
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
            min_width = breakpoints.nixShell;
            foreground = "cyan";
            template = ''{{ if ne .Type "unknown" }} ${nixIcon} nix-shell{{ end }}'';
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
