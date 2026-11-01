{ ... }:
let
  # nf-md-lambda
  # lambda = "";
  lambda = "󰘧";

  # Icons matching the powerlevel10k nerdfont-v3 defaults
  homeIcon = ""; # nf-fa-home
  homeSubIcon = ""; # nf-fa-folder_open
  folderIcon = ""; # nf-fa-folder_open_o
  branchIcon = ""; # nf-fa-code_fork

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
            # Home icon in ~, open folder icon below ~, folder icon elsewhere
            template = "{{ if eq .Location .Env.HOME }}${homeIcon}{{ else if hasPrefix (printf \"%s/\" .Env.HOME) .Location }}${homeSubIcon}{{ else }}${folderIcon}{{ end }} {{ .Path }} ";
            options = {
              style = "full";
            };
          }
          {
            type = "git";
            style = "plain";
            foreground = "magenta";
            template = "{{ if .UpstreamIcon }}{{ .UpstreamIcon }} {{ end }}{{ .HEAD }}{{ if .Working.Changed }} {{ .Working.String }}{{ end }}{{ if .Staging.Changed }} {{ .Staging.String }}{{ end }}";
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
    # transient_prompt = lambdaSegment;
  };
}
