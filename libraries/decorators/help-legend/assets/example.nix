/*
  Synthetic README example. The real POSIX renderer owns all printed text;
  assets/tools/render-help-example.py captures it and wraps it as SVG.
*/
let
  help = import ../. { };
  renderer = help.libHelpLegendRenderer.posix;
  legend = {
    build = "Build the project output";
    test = "Run the test suite";
    lint = "Run formatting and lint checks";
    release = "Create the release artifact";
  };
  groups = [
    {
      name = "Project";
      cmds = [
        "build"
        "test"
        "lint"
      ];
    }
    {
      name = "Release";
      cmds = [ "release" ];
    }
  ];
  descFn = cmd: legend.${cmd};
  layout = help.sectionLayout { inherit groups descFn; };
  section = help.mkHelpSection {
    inherit groups descFn layout;
    libHelpLegendRenderer = renderer;
    cmdColor = "";
    headerColor = "";
    reset = "";
  };
in
''
  ${help.mkCenteredTitle {
    libHelpLegendRenderer = renderer;
    title = "Daily Tools";
    width = layout.width;
    leadingNewlines = 0;
    color = "";
    reset = "";
  }}
  ${section.text}
  printf '\n'
''
