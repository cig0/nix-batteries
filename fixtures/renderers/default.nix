/*
  Renderer fixture for the public help-legend and git-state libraries.

  fixtures/default.nix supplies nixpkgs and sidecarLibs. This fixture generates
  shell snippets and checks their rendered contracts and native shell syntax.
*/
{
  sidecarLibs,
  lib,
  pass,
  pkgs,
}:

let
  helpLegend = sidecarLibs.helpLegendDecorator;
  theme = sidecarLibs.themes.resolve {
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

  renderHelp = libHelpLegendRenderer: {
    section = helpLegend.mkHelpSection {
      inherit
        descFn
        groups
        layout
        libHelpLegendRenderer
        ;
      cmdColor = theme.theme.bold_zero;
      headerColor = theme.theme.bold_four;
      reset = theme.mode.reset;
    };
    check = helpLegend.mkHelpCheck {
      inherit layout libHelpLegendRenderer;
      cmd = "check";
      desc = descFn "check";
      cmdColor = theme.theme.bold_zero;
      reset = theme.mode.reset;
    };
    title = helpLegend.mkCenteredTitle {
      inherit libHelpLegendRenderer;
      color = theme.theme.bold_zero;
      reset = theme.mode.reset;
      title = "Fixture Help";
      width = layout.width;
    };
  };

  renderedHelp = lib.mapAttrs (_: renderHelp) helpLegend.libHelpLegendRenderer;
  gitRepoState = sidecarLibs.gitRepoState;

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
    assert lib.hasInfix "_gitRevision" gitRepoState.revisionFunction.posix;
    assert lib.hasInfix "function _gitRevision" gitRepoState.revisionFunction.fish;
    assert lib.hasInfix "def _gitRevision" gitRepoState.revisionFunction.nushell;
    assert !(lib.hasInfix "$args" renderedHelp.nushell.check);
    assert lib.hasInfix "native -h/--help" renderedHelp.nushell.check;
    assert lib.hasInfix "\\u{1b}[" renderedHelp.nushell.section.text;
    assert !(lib.hasInfix "\\e[" renderedHelp.nushell.section.text);
    pass "nix-batteries-decorator-fixture";

  renderer-runtime-fixture = pkgs.runCommand "nix-batteries-renderer-runtime-fixture" { } ''
    ${pkgs.bash}/bin/bash -n ${sources.gitPosix}
    ${pkgs.bash}/bin/bash -n ${sources.helpPosix}
    ${pkgs.zsh}/bin/zsh -n ${sources.gitPosix}
    ${pkgs.zsh}/bin/zsh -n ${sources.helpPosix}

    ${pkgs.fish}/bin/fish --no-execute ${sources.gitFish}
    ${pkgs.fish}/bin/fish --no-execute ${sources.helpFish}

    ${pkgs.nushell}/bin/nu --commands 'if (nu-check ${sources.gitNu}) == false { exit 1 }'
    ${pkgs.nushell}/bin/nu --commands 'if (nu-check ${sources.helpNu}) == false { exit 1 }'

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

    touch "$out"
  '';
}
