{ lib, ... }:
{
  options.tests.modulon.valid = lib.mkEnableOption "Valid Modulon fixture module";
  config.tests.modulon.loaded = true;
}
