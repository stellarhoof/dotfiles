{ config, pkgs, ... }:

with pkgs.lib;

let

  colors =
    with config.lib.colors.theme;
    with config.lib.colors.palette;
    with config.lib.colors.attrs;
    rec {
      # Command line
      fish_color_normal = fg;
      fish_color_command = fg;
      fish_color_quote = string;
      fish_color_redirection = fg;
      fish_color_end = fg;
      fish_color_error = error;
      fish_color_param = base5;
      fish_color_comment = comment;
      fish_color_match = green;
      fish_color_selection = fg; # Selected text in Vi mode
      fish_color_operator = base5;
      fish_color_escape = orange;

      # Prompt
      fish_color_cwd = green // bold;
      fish_color_user = base5 // bold;
      fish_color_host = base5 // bold;
      fish_color_prompt = base5 // bold; # Non-standard. Only for my custom prompt function

      # Others
      fish_color_autosuggestion = comment; # History suggestion when typing a command
      fish_color_cancel = red; # ^C character when canceling a command

      # Autocompletion/pager
      # *_prefix: Highlighted substring
      # *_completion: Suggested string foreground
      # *_background: Suggested string background
      # *_description: Short description next to suggested string

      fish_pager_color_progress = highlight; # Progress bar at the bottom left corner

      # Unselected suggestions
      fish_pager_color_prefix = highlight;
      fish_pager_color_completion = suggestionFg;
      fish_pager_color_background = { background = suggestionBg.color; };
      fish_pager_color_description = suggestionFg // italic;

      # Selected suggestions
      fish_pager_color_selected_prefix = fish_pager_color_prefix;
      fish_pager_color_selected_completion = suggestionSelectedFg;
      fish_pager_color_selected_background = { background = suggestionSelectedBg.color; };
      fish_pager_color_selected_description = suggestionSelectedFg // italic;

      # For compatibility until new versions of fish support the variables
      # above (a PR has already been merged)
      fish_color_search_match = fish_pager_color_selected_background;

      # Every second unselected suggestion
      fish_pager_color_secondary_prefix = fish_pager_color_prefix;
      fish_pager_color_secondary_completion = fish_pager_color_completion;
      fish_pager_color_secondary_background = fish_pager_color_background;
      fish_pager_color_secondary_description = fish_pager_color_description;
    };

  # TODO: Use optionalAttrs
  buildColorString = with builtins; color: concatStringsSep "" [
    (if hasAttr "color" color then "'${color.color}'" else "")
    (if hasAttr "background" color then "--background='${color.background}'" else "")
    (if hasAttr "italic" color then " --italics" else "")
    (if hasAttr "bold" color then " --bold" else "")
    (if hasAttr "underline" color then " --underline" else "")
  ];

  colorString = color: if isString color then "'${color}'" else buildColorString color;

in

{
  programs = {
    fish = {
      enable = true;

      loginShellInit =
        with builtins;
        with config.lib.colors.theme;
        with config.lib.colors.palette;
        ''
          set -U fish_prompt_pwd_dir_length 5
          ${concatStringsSep "\n" (
            attrValues (mapAttrs (k: v: "set -U ${k} ${buildColorString v}") colors)
          )}
        '';

      interactiveShellInit = ''
        set fish_greeting
        ${concatStringsSep "\n" (
          mapAttrsToList (k: v: ''alias --save ${k}="${v}"'') 
          config.lib.aliases
        )}
      '';
    };
  };

  xdg.configFile = {
    "fish/functions" = {
      recursive = true;
      source = ./functions;
    };

    "fish/functions/fish_colors.fish".text = with builtins; ''
      function fish_colors --description 'Output all fish color variables'
        ${concatStringsSep "\n" (
          map (k: ''set_color ''$${k}; echo "${k}"; set_color normal'') (attrNames colors)
        )}
      end
    '';

    "fish/functions/fisher.fish".source = builtins.fetchurl "https://raw.githubusercontent.com/jorgebucaran/fisher/master/fisher.fish?nocache";

    "fish/fishfile" = {
      onChange = "fish -c fisher";
      text = ''
        jethrokuan/fzf
      '';
    };
  };
}
