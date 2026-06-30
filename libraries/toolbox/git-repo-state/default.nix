{
  revisionFunctionName ? "_gitRevision",
  dirtyStateFunctionName ? "_gitDirtyState",
  unknownRevisionText ? "unknown",
  dirtyStateText ? "dirty",
  repositoryPathEnvVar ? "GIT_REPO_PATH",
}:
let
  posixRepositoryPath = "$" + "{${repositoryPathEnvVar}:-.}";
in
{
  inherit
    dirtyStateFunctionName
    dirtyStateText
    repositoryPathEnvVar
    revisionFunctionName
    unknownRevisionText
    ;

  revisionFunction = {
    posix = ''
      ${revisionFunctionName}() {
        local shortHash
        shortHash="$(git -C "${posixRepositoryPath}" rev-parse --short HEAD 2>/dev/null)" || shortHash=""
        if [[ -z "''${shortHash}" ]]; then
          printf '%s' "${unknownRevisionText}"
        else
          printf '%s' "''${shortHash}"
        fi
      }
    '';

    fish = ''
      function ${revisionFunctionName}
        set -l repository_path "."
        if set -q ${repositoryPathEnvVar}
          set repository_path "${"$"}${repositoryPathEnvVar}"
        end

        set -l short_hash (git -C "$repository_path" rev-parse --short HEAD 2>/dev/null)
        if test -z "$short_hash"
          printf '%s' "${unknownRevisionText}"
        else
          printf '%s' "$short_hash"
        end
      end
    '';

    nushell = ''
      def ${revisionFunctionName} [] {
        let repository_path = ($env.${repositoryPathEnvVar}? | default ".")
        let short_hash = try {
          git -C $repository_path rev-parse --short HEAD | str trim
        } catch {
          ""
        }

        if ($short_hash == "") {
          "${unknownRevisionText}"
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
      ${dirtyStateFunctionName}() {
        if [[ -n "$(git -C "${posixRepositoryPath}" status --porcelain 2>/dev/null)" ]]; then
          printf '%s' "${dirtyStateText}"
        fi
      }
    '';

    fish = ''
      function ${dirtyStateFunctionName}
        set -l repository_path "."
        if set -q ${repositoryPathEnvVar}
          set repository_path "${"$"}${repositoryPathEnvVar}"
        end

        set -l dirty (git -C "$repository_path" status --porcelain 2>/dev/null)
        if test (count $dirty) -gt 0
          printf '%s' "${dirtyStateText}"
        end
      end
    '';

    nushell = ''
      def ${dirtyStateFunctionName} [] {
        let repository_path = ($env.${repositoryPathEnvVar}? | default ".")
        let dirty = try {
          git -C $repository_path status --porcelain | str trim
        } catch {
          ""
        }

        if ($dirty != "") {
          "${dirtyStateText}"
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
