{
  flakeVersionFuncName ? "_flakeVersion",
  flakeDirtyStateFuncName ? "_flakeDirtyState",
  flakeVersionFallback ? "git-unknown",
  flakeDirtyStateText ? "dirty",
  flakePathEnvVar ? "FLAKE_SRC_PATH",
}:
let
  posixFlakePath = "$" + "{${flakePathEnvVar}:-.}";
in
{
  inherit
    flakeDirtyStateFuncName
    flakeDirtyStateText
    flakePathEnvVar
    flakeVersionFallback
    flakeVersionFuncName
    ;

  flakeVersionFunc = {
    posix = ''
      ${flakeVersionFuncName}() {
        local shortHash
        shortHash="$(git -C "${posixFlakePath}" rev-parse --short HEAD 2>/dev/null)" || shortHash=""
        if [[ -z "''${shortHash}" ]]; then
          printf '%s' "${flakeVersionFallback}"
        else
          printf '%s' "git-''${shortHash}"
        fi
      }
    '';

    fish = ''
      function ${flakeVersionFuncName}
        set -l flake_path "."
        if set -q ${flakePathEnvVar}
          set flake_path "$${flakePathEnvVar}"
        end

        set -l short_hash (git -C "$flake_path" rev-parse --short HEAD 2>/dev/null)
        if test -z "$short_hash"
          printf '%s' "${flakeVersionFallback}"
        else
          printf '%s' "git-$short_hash"
        end
      end
    '';

    nushell = ''
      def ${flakeVersionFuncName} [] {
        let flake_path = ($env.${flakePathEnvVar}? | default ".")
        let short_hash = try {
          git -C $flake_path rev-parse --short HEAD | str trim
        } catch {
          ""
        }

        if ($short_hash == "") {
          "${flakeVersionFallback}"
        } else {
          $"git-($short_hash)"
        }
      }
    '';
  };

  flakeVersionCall = {
    posix = "${flakeVersionFuncName}";
    fish = "${flakeVersionFuncName}";
    nushell = "print --no-newline (${flakeVersionFuncName})";
  };

  flakeDirtyStateFunc = {
    posix = ''
      ${flakeDirtyStateFuncName}() {
        if [[ -n "$(git -C "${posixFlakePath}" status --porcelain 2>/dev/null)" ]]; then
          printf '%s' "${flakeDirtyStateText}"
        fi
      }
    '';

    fish = ''
      function ${flakeDirtyStateFuncName}
        set -l flake_path "."
        if set -q ${flakePathEnvVar}
          set flake_path "$${flakePathEnvVar}"
        end

        set -l dirty (git -C "$flake_path" status --porcelain 2>/dev/null)
        if test (count $dirty) -gt 0
          printf '%s' "${flakeDirtyStateText}"
        end
      end
    '';

    nushell = ''
      def ${flakeDirtyStateFuncName} [] {
        let flake_path = ($env.${flakePathEnvVar}? | default ".")
        let dirty = try {
          git -C $flake_path status --porcelain | str trim
        } catch {
          ""
        }

        if ($dirty != "") {
          "${flakeDirtyStateText}"
        } else {
          ""
        }
      }
    '';
  };

  flakeDirtyStateCall = {
    posix = "${flakeDirtyStateFuncName}";
    fish = "${flakeDirtyStateFuncName}";
    nushell = "print --no-newline (${flakeDirtyStateFuncName})";
  };
}
