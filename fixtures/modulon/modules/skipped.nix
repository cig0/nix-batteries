# @MODULON_SKIP
{ lib, ... }:
{
  options.tests.modulon.skipped = lib.mkEnableOption "Skipped Modulon fixture module";
  config.tests.modulon.skipped = true;
}
