/*
  Cross-shell Git repository-state snippet generator.

  Callers configure function names and fallback text; this library returns
  POSIX, Fish, and Nushell source snippets plus their matching call forms.
  Consumers own snippet installation and display decisions.
*/
{
  revisionFunctionName ? "_gitRevision", # consumer → revision shell function name
  dirtyStateFunctionName ? "_gitDirtyState", # consumer → dirty-state shell function name
  unknownRevisionText ? "unknown", # consumer → unknown-revision fallback label
  dirtyStateText ? "dirty", # consumer → dirty-state fallback label
  repositoryPathEnvVar ? "GIT_REPO_PATH", # consumer → repository path environment variable
}:
let
  posixRepositoryPath = "$" + "{${repositoryPathEnvVar}:-.}";
  # A shared, conservative grammar keeps identifiers valid in all three shells.
  reservedNames = [
    "if"
    "then"
    "else"
    "elif"
    "fi"
    "for"
    "while"
    "until"
    "do"
    "done"
    "case"
    "esac"
    "in"
    "function"
    "end"
    "switch"
    "begin"
    "return"
    "break"
    "continue"
    "def"
    "let"
    "mut"
    "const"
    "export"
    "try"
    "catch"
    "match"
    "select"
    "time"
    "coproc"
    "repeat"
    "foreach"
    "nocorrect"
    "noglob"
    "and"
    "or"
    "not"
    "alias"
    "source"
    "use"
    "module"
    "overlay"
    "hide"
    "extern"
    "loop"
  ];
  validIdentifier =
    name: builtins.isString name && builtins.match "[a-zA-Z_][a-zA-Z0-9_]*" name != null;
  validFunctionName =
    name:
    validIdentifier name
    && !(builtins.elem name (
      reservedNames
      ++ [
        "git"
        "printf"
        "test"
        "set"
        "count"
        "print"
        "error"
      ]
    ));
  # These literals feed %s, not the help renderer's escape-interpreting %b.
  posixLiteral = text: "'" + builtins.replaceStrings [ "'" ] [ "'\\''" ] text + "'";
  fishLiteral = text: "'" + builtins.replaceStrings [ "\\" "'" ] [ "\\\\" "\\'" ] text + "'";
  nuLiteral =
    text:
    "\""
    + builtins.replaceStrings [ "\\" "\"" "\n" "\r" "\t" ] [ "\\\\" "\\\"" "\\n" "\\r" "\\t" ] text
    + "\"";
in
assert validFunctionName revisionFunctionName || throw "gitRepoState: invalid revisionFunctionName";
assert
  validFunctionName dirtyStateFunctionName || throw "gitRepoState: invalid dirtyStateFunctionName";
assert
  revisionFunctionName != dirtyStateFunctionName || throw "gitRepoState: function names must differ";
assert validIdentifier repositoryPathEnvVar || throw "gitRepoState: invalid repositoryPathEnvVar";
{
  inherit
    dirtyStateFunctionName
    dirtyStateText
    repositoryPathEnvVar
    revisionFunctionName
    unknownRevisionText
    ;

  revisionFunction = {
    # Subshell scope avoids leaking variables or shadowing a configured env name
    # before reading its value, without depending on non-POSIX `local`.
    posix = ''
      ${revisionFunctionName}() (
        shortHash="$(git -C "${posixRepositoryPath}" rev-parse --short HEAD 2>/dev/null)" || shortHash=""
        if [ -z "''${shortHash}" ]; then
          printf '%s' ${posixLiteral unknownRevisionText}
        else
          printf '%s' "''${shortHash}"
        fi
      )
    '';

    fish = ''
      function ${revisionFunctionName}
        set -l repository_path "${"$"}${repositoryPathEnvVar}"
        if test -z "$repository_path"
          set repository_path "."
        end

        set -l short_hash (git -C "$repository_path" rev-parse --short HEAD 2>/dev/null)
        if test -z "$short_hash"
          printf '%s' ${fishLiteral unknownRevisionText}
        else
          printf '%s' "$short_hash"
        end
      end
    '';

    nushell = ''
      def ${revisionFunctionName} [] {
        let repository_path = ($env.${repositoryPathEnvVar}? | default ".")
        let short_hash = try {
          let result = (^git -C $repository_path rev-parse --short HEAD | complete)
          if $result.exit_code == 0 { $result.stdout | str trim } else { "" }
        } catch {
          ""
        }

        if ($short_hash == "") {
          ${nuLiteral unknownRevisionText}
        } else {
          $short_hash
        }
      }
    '';
  };

  revisionCall = {
    posix = "${revisionFunctionName}";
    fish = "${revisionFunctionName}";
    nushell = "print --no-newline (${revisionFunctionName})";
  };

  dirtyStateFunction = {
    posix = ''
      ${dirtyStateFunctionName}() (
        dirty="$(git -C "${posixRepositoryPath}" status --porcelain)" || return "$?"
        if [ -n "$dirty" ]; then
          printf '%s' ${posixLiteral dirtyStateText}
        fi
      )
    '';

    fish = ''
      function ${dirtyStateFunctionName}
        set -l repository_path "${"$"}${repositoryPathEnvVar}"
        if test -z "$repository_path"
          set repository_path "."
        end

        set -l dirty (git -C "$repository_path" status --porcelain)
        set -l git_status $status
        if test $git_status -ne 0
          return $git_status
        end
        if test (count $dirty) -gt 0
          printf '%s' ${fishLiteral dirtyStateText}
        end
        return 0
      end
    '';

    nushell = ''
      def ${dirtyStateFunctionName} [] {
        let repository_path = ($env.${repositoryPathEnvVar}? | default ".")
        let result = (^git -C $repository_path status --porcelain | complete)
        if $result.exit_code != 0 {
          error make { msg: $"gitRepoState: git status failed: ($result.stderr | str trim)" }
        }

        if ($result.stdout != "") {
          ${nuLiteral dirtyStateText}
        } else {
          ""
        }
      }
    '';
  };

  dirtyStateCall = {
    posix = "${dirtyStateFunctionName}";
    fish = "${dirtyStateFunctionName}";
    nushell = "print --no-newline (${dirtyStateFunctionName})";
  };
}
