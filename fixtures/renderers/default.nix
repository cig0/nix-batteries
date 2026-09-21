/*
  Renderer fixture for the public help-legend and git-state libraries.

  fixtures/default.nix supplies nixpkgs and batteriesLib. This fixture generates
  shell snippets and checks their rendered contracts, native shell syntax, and
  runtime output when a caller-authored payload contains shell metacharacters.
*/
{
  batteriesLib, # fixtures/default.nix → batteriesLib
  lib, # fixtures/default.nix → nixpkgs.lib
  pass, # fixtures/default.nix → fixture pass command
  pkgs, # fixtures/default.nix → per-system package set
}:

let
  helpLegend = batteriesLib.helpLegendDecorator;
  theme = batteriesLib.themes.resolve {
    name = "nushell-inspired";
    enableColors = true;
  };

  groups = [
    {
      name = "Fixture";
      cmds = [ "check" ];
    }
  ];
  descFn = _: "Run fixture check";
  layout = helpLegend.sectionLayout { inherit groups descFn; };

  # Caller-authored payload holding every character a renderer must neutralize:
  # shell expansion (`$`), quoting, command substitution (backtick), and a
  # literal backslash that must survive both the shell and `printf '%b'`.
  trickyText = ''cost $5 and say "hi" and tick` and back\slash'';
  trickyGroupName = "Tricky $group";
  trickyTitle = ''Title $1 "quoted" `tick` back\slash'';
  trickyGroups = [
    {
      name = trickyGroupName;
      cmds = [ "check" ];
    }
  ];
  trickyDescFn = _: trickyText;

  # One renderer over one payload set. Layout is recomputed because column
  # padding depends on the description length.
  mkRenderedHelp =
    {
      descFn,
      groups,
      title,
    }:
    libHelpLegendRenderer:
    let
      layout = helpLegend.sectionLayout { inherit groups descFn; };
    in
    {
      section = helpLegend.mkHelpSection {
        inherit
          descFn
          groups
          layout
          libHelpLegendRenderer
          ;
        cmdColor = theme.theme.bold.emphasis;
        headerColor = theme.theme.bold.accent;
        reset = theme.mode.reset;
      };
      check = helpLegend.mkHelpCheck {
        inherit layout libHelpLegendRenderer;
        cmd = "check";
        desc = descFn "check";
        cmdColor = theme.theme.bold.emphasis;
        reset = theme.mode.reset;
      };
      title = helpLegend.mkCenteredTitle {
        inherit libHelpLegendRenderer;
        color = theme.theme.bold.accent;
        reset = theme.mode.reset;
        inherit title;
        width = layout.width;
      };
    };

  renderedHelp = lib.mapAttrs (
    _:
    mkRenderedHelp {
      inherit descFn groups;
      title = "Fixture Help";
    }
  ) (helpLegend.libHelpLegendRenderer);
  trickyHelp = lib.mapAttrs (
    _:
    mkRenderedHelp {
      descFn = trickyDescFn;
      groups = trickyGroups;
      title = trickyTitle;
    }
  ) (helpLegend.libHelpLegendRenderer);

  gitRepoState = batteriesLib.gitRepoState;

  wideIndentLayout = helpLegend.sectionLayout {
    inherit groups descFn;
    indent = 6;
  };
  layoutSources = lib.mapAttrs (
    shell: renderer:
    let
      section = helpLegend.mkHelpSection {
        inherit groups descFn;
        layout = wideIndentLayout;
        libHelpLegendRenderer = renderer;
        cmdColor = "";
        headerColor = "";
        reset = "";
      };
      emptySection = helpLegend.mkHelpSection {
        groups = [ ];
        inherit descFn;
        libHelpLegendRenderer = renderer;
        cmdColor = "";
        headerColor = "";
        reset = "";
      };
      title = helpLegend.mkCenteredTitle {
        libHelpLegendRenderer = renderer;
        color = "";
        reset = "";
        title = "A long title";
        width = 2;
        leadingNewlines = 0;
      };
      guard = helpLegend.mkHelpCheck {
        layout = wideIndentLayout;
        libHelpLegendRenderer = renderer;
        cmd = "check";
        desc = descFn "check";
        cmdColor = "";
        reset = "";
      };
    in
    pkgs.writeText "layout-${shell}" (
      ''
        ${title}
        ${section.text}
        ${emptySection.text}
      ''
      + (
        if shell == "posix" then
          ''
            guarded() {
              ${guard}
              printf '%s' UNREACHABLE
            }
            guarded --help
          ''
        else if shell == "fish" then
          ''
            function guarded
              ${guard}
              printf '%s' UNREACHABLE
            end
            guarded --help
          ''
        else
          ""
      )
    )
  ) helpLegend.libHelpLegendRenderer;
  layoutExpected = pkgs.writeText "layout-expected" "A long title\nFixture\n      check  Run fixture check\n      check  Run fixture check\n";
  layoutNuExpected = pkgs.writeText "layout-nu-expected" "A long title\nFixture\n      check  Run fixture check";

  sources = {
    gitPosix = pkgs.writeText "git-state.sh" ''
      ${gitRepoState.revisionFunction.posix}
      ${gitRepoState.dirtyStateFunction.posix}

      ${gitRepoState.revisionCall.posix}
      ${gitRepoState.dirtyStateCall.posix}
    '';
    helpPosix = pkgs.writeText "help-legend.sh" ''
      fixture_help() {
        ${renderedHelp.posix.check}
        ${renderedHelp.posix.title}
        ${renderedHelp.posix.section.text}
      }
    '';
    gitFish = pkgs.writeText "git-state.fish" ''
      ${gitRepoState.revisionFunction.fish}
      ${gitRepoState.dirtyStateFunction.fish}

      ${gitRepoState.revisionCall.fish}
      ${gitRepoState.dirtyStateCall.fish}
    '';
    helpFish = pkgs.writeText "help-legend.fish" ''
      function fixture_help
        ${renderedHelp.fish.check}
        ${renderedHelp.fish.title}
        ${renderedHelp.fish.section.text}
      end
    '';
    gitNu = pkgs.writeText "git-state.nu" ''
      ${gitRepoState.revisionFunction.nushell}
      ${gitRepoState.dirtyStateFunction.nushell}

      ${gitRepoState.revisionCall.nushell}
      ${gitRepoState.dirtyStateCall.nushell}
    '';
    helpNu = pkgs.writeText "help-legend.nu" ''
      def fixture-help [] {
        ${renderedHelp.nushell.check}
        ${renderedHelp.nushell.title}
        ${renderedHelp.nushell.section.text}
      }

      fixture-help
    '';
    # The function prints the one-line guard when called with --help and the full
    # screen otherwise, so one invocation of each source exercises both paths.
    trickyPosix = pkgs.writeText "tricky-help-legend.sh" ''
      set -u
      fixture_tricky_help() {
        ${trickyHelp.posix.check}
        ${trickyHelp.posix.title}
        ${trickyHelp.posix.section.text}
      }

      fixture_tricky_help --help
      fixture_tricky_help
    '';
    trickyFish = pkgs.writeText "tricky-help-legend.fish" ''
      function fixture_tricky_help
        ${trickyHelp.fish.check}
        ${trickyHelp.fish.title}
        ${trickyHelp.fish.section.text}
      end

      fixture_tricky_help --help
      fixture_tricky_help
    '';
    trickyNu = pkgs.writeText "tricky-help-legend.nu" ''
      def fixture-tricky-help [] {
        ${trickyHelp.nushell.check}
        ${trickyHelp.nushell.title}
        ${trickyHelp.nushell.section.text}
      }

      fixture-tricky-help
    '';
  };
in
{
  decorator-fixture =
    assert layout.descCol == 9;
    assert layout.maxDescLen == 17;
    assert lib.hasInfix "printf '%b'" renderedHelp.posix.section.text;
    assert lib.hasInfix "printf '%b'" renderedHelp.fish.section.text;
    assert lib.hasInfix "print --no-newline" renderedHelp.nushell.section.text;
    assert lib.hasInfix "Fixture Help" renderedHelp.posix.title;
    assert lib.hasInfix "Fixture Help" renderedHelp.fish.title;
    assert lib.hasInfix "Fixture Help" renderedHelp.nushell.title;
    # The POSIX guard stays inside the POSIX shell grammar.
    assert !(lib.hasInfix "[[" renderedHelp.posix.check);
    assert lib.hasInfix "[ \"\${1-}\" = \"-h\" ]" renderedHelp.posix.check;
    # `printf '%b'` understands `\e` only on bash/zsh; colours use `\033` so
    # dash renders them too, and a payload backslash cannot forge that sequence.
    assert lib.hasInfix "\\033[" renderedHelp.posix.section.text;
    assert !(lib.hasInfix "\\e[" renderedHelp.posix.section.text);
    assert lib.hasInfix "\\033[" renderedHelp.posix.check;
    assert !(lib.hasInfix "\\e[" renderedHelp.posix.check);
    assert !(lib.hasInfix "\\e[" trickyHelp.posix.section.text);
    # Escaping rules per renderer: only expansion characters the shell owns.
    assert helpLegend.libHelpLegendRenderer.posix.escape "$" == "\\$";
    assert helpLegend.libHelpLegendRenderer.posix.escape "`" == "\\`";
    assert helpLegend.libHelpLegendRenderer.posix.escape "\"" == "\\\"";
    assert helpLegend.libHelpLegendRenderer.posix.escape "a\\b" == "a\\0134b";
    assert helpLegend.libHelpLegendRenderer.fish.escape "$" == "\\$";
    assert helpLegend.libHelpLegendRenderer.fish.escape "`" == "`";
    assert helpLegend.libHelpLegendRenderer.fish.escape "a\\b" == "a\\\\\\\\b";
    assert helpLegend.libHelpLegendRenderer.nushell.escape "$" == "$";
    assert helpLegend.libHelpLegendRenderer.nushell.escape "`" == "`";
    assert helpLegend.libHelpLegendRenderer.nushell.escape "\"" == "\\\"";
    assert helpLegend.libHelpLegendRenderer.nushell.escape "a\\b" == "a\\u{5c}b";
    # Public layout helpers that no other fixture exercises.
    assert helpLegend.repeat 3 "ab" == "ababab";
    assert
      helpLegend.maxStringLength [
        "a"
        "bb"
        "ccc"
      ] == 3;
    assert
      helpLegend.maxInt [
        4
        1
        9
        2
      ] == 9;
    assert helpLegend.centerIn 11 "abc" == helpLegend.repeat 4 " ";
    assert helpLegend.centerIn 2 "A long title" == "";
    assert wideIndentLayout.descCol == 13;
    assert wideIndentLayout.indentText == "      ";
    assert helpLegend.enabledWidth [ ] == 0;
    assert
      helpLegend.mkCenteredTitle {
        color = "";
        reset = "";
        title = "T";
        width = 1;
        leadingLines = 0;
      } == ''printf '%b' "\nT"'';
    assert
      helpLegend.mkCenteredTitle {
        color = "";
        reset = "";
        title = "T";
        width = 1;
        leadingNewlines = 0;
      } == ''printf '%b' "T"'';
    assert
      helpLegend.enabledWidth [
        { width = 5; }
        { width = 12; }
      ] == 12;
    assert lib.hasInfix "_gitRevision" gitRepoState.revisionFunction.posix;
    assert !(lib.hasInfix "[[" gitRepoState.revisionFunction.posix);
    assert !(lib.hasInfix "[[" gitRepoState.dirtyStateFunction.posix);
    assert lib.hasInfix "function _gitRevision" gitRepoState.revisionFunction.fish;
    assert lib.hasInfix "def _gitRevision" gitRepoState.revisionFunction.nushell;
    assert !(lib.hasInfix "$args" renderedHelp.nushell.check);
    assert lib.hasInfix "native -h/--help" renderedHelp.nushell.check;
    assert lib.hasInfix "\\u{1b}[" renderedHelp.nushell.section.text;
    assert !(lib.hasInfix "\\e[" renderedHelp.nushell.section.text);
    pass "nix-batteries-decorator-fixture";

  renderer-runtime-fixture = pkgs.runCommand "nix-batteries-renderer-runtime-fixture" { } ''
    ${pkgs.bash}/bin/bash ${layoutSources.posix} > layout-bash.out
    ${pkgs.zsh}/bin/zsh ${layoutSources.posix} > layout-zsh.out
    ${pkgs.dash}/bin/dash ${layoutSources.posix} > layout-dash.out
    ${pkgs.fish}/bin/fish ${layoutSources.fish} > layout-fish.out
    ${pkgs.nushell}/bin/nu ${layoutSources.nushell} > layout-nu.out
    for outfile in layout-bash.out layout-zsh.out layout-dash.out layout-fish.out; do
      ${pkgs.diffutils}/bin/cmp ${layoutExpected} "$outfile"
    done
    ${pkgs.diffutils}/bin/cmp ${layoutNuExpected} layout-nu.out
    ${pkgs.bash}/bin/bash -n ${sources.gitPosix}
    ${pkgs.bash}/bin/bash -n ${sources.helpPosix}
    ${pkgs.bash}/bin/bash -n ${sources.trickyPosix}
    ${pkgs.zsh}/bin/zsh -n ${sources.gitPosix}
    ${pkgs.zsh}/bin/zsh -n ${sources.helpPosix}
    ${pkgs.zsh}/bin/zsh -n ${sources.trickyPosix}
    ${pkgs.dash}/bin/dash -n ${sources.gitPosix}
    ${pkgs.dash}/bin/dash -n ${sources.helpPosix}
    ${pkgs.dash}/bin/dash -n ${sources.trickyPosix}

    ${pkgs.fish}/bin/fish --no-execute ${sources.gitFish}
    ${pkgs.fish}/bin/fish --no-execute ${sources.helpFish}
    ${pkgs.fish}/bin/fish --no-execute ${sources.trickyFish}

    ${pkgs.nushell}/bin/nu --commands 'if (nu-check ${sources.gitNu}) == false { exit 1 }'
    ${pkgs.nushell}/bin/nu --commands 'if (nu-check ${sources.helpNu}) == false { exit 1 }'
    ${pkgs.nushell}/bin/nu --commands 'if (nu-check ${sources.trickyNu}) == false { exit 1 }'

    ${pkgs.gnugrep}/bin/grep --fixed-strings '\u{1b}[' ${sources.helpNu}
    if ${pkgs.gnugrep}/bin/grep --fixed-strings --quiet '\e[' ${sources.helpNu}; then
      exit 1
    fi
    if ${pkgs.gnugrep}/bin/grep --quiet "$(${pkgs.coreutils}/bin/printf '\033')" ${sources.helpNu}; then
      exit 1
    fi

    ${pkgs.nushell}/bin/nu ${sources.helpNu} > help-nu.out
    ${pkgs.coreutils}/bin/od -An -tx1 help-nu.out \
      | ${pkgs.coreutils}/bin/tr -d ' \n' \
      | ${pkgs.gnugrep}/bin/grep --quiet '1b5b'

    # A caller-authored payload must survive execution, not only parsing.
    ${pkgs.bash}/bin/bash ${sources.trickyPosix} > tricky-bash.out
    ${pkgs.zsh}/bin/zsh ${sources.trickyPosix} > tricky-zsh.out
    ${pkgs.dash}/bin/dash ${sources.trickyPosix} > tricky-dash.out
    ${pkgs.fish}/bin/fish ${sources.trickyFish} > tricky-fish.out
    ${pkgs.nushell}/bin/nu ${sources.trickyNu} > tricky-nu.out
    for outfile in tricky-bash.out tricky-zsh.out tricky-dash.out tricky-fish.out tricky-nu.out; do
      ${pkgs.gnugrep}/bin/grep --fixed-strings '${trickyText}' "$outfile"
      ${pkgs.gnugrep}/bin/grep --fixed-strings '${trickyGroupName}' "$outfile"
      ${pkgs.gnugrep}/bin/grep --fixed-strings '${trickyTitle}' "$outfile"
    done

    # dash's printf does not understand `\e`; the POSIX renderer must emit `\033`.
    ${pkgs.coreutils}/bin/od -An -tx1 tricky-dash.out \
      | ${pkgs.coreutils}/bin/tr -d ' \n' \
      | ${pkgs.gnugrep}/bin/grep --quiet '1b5b'
    if ${pkgs.gnugrep}/bin/grep --fixed-strings --quiet '\e[' tricky-dash.out; then
      exit 1
    fi

    touch "$out"
  '';
}
