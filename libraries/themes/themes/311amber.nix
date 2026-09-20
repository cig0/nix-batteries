# Theme module. Do not remove this header.
# 311 Amber CRT — vintage phosphor monitor aesthetic
{ }:
{
  # Preserve the existing 311amber rendering exactly.
  boldFactor = 1.0;
  dimFactor = 0.55;

  # Interactive selectors use a high-contrast theme-owned pair instead of
  # inferring UI roles from semantic roles. Consumers receive raw #RRGGBB.
  selection = {
    background = "#ffff00"; # Yellow
    foreground = "#000000"; # Black
  };

  roles = {
    accent = "#ffb343"; # Vibrant orange
    emphasis = "#f8fafc"; # Muted-ish white
    option = "#0080ff"; # Azure
    success = "#00ff7f"; # Vibrant green
    value = "#ffff00"; # Yellow
    warning = "#ffff00"; # Yellow
    error = "#ff0000"; # Red
    notice = "#ffc0cb"; # Pink
    context = "#00ff7f"; # Vibrant green
  };
}
