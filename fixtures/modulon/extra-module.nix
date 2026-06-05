{ lib, ... }:
{
  options.tests.modulon.extra = lib.mkEnableOption "Extra Modulon fixture module";
  config.tests.modulon.extra = true;
}
