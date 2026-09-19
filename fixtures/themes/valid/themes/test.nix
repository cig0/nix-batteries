# Theme module. Fixture theme.
{ }:
{
  boldFactor = 1.5;
  dimFactor = 0.5;

  roles = {
    accent = "#204060";
    emphasis = "#102030";
    option = "#304050";
    success = "#405060";
    value = "#506070";
    # Light enough that boldFactor 1.5 clamps every channel to 255.
    warning = "#f0f0f0";
    error = "#607080";
    notice = "#708090";
    context = "#8090a0";

    # Optional extra role. Its presentations are generated without any
    # library edit, and it must not appear in provenance or the raw palette
    # as anything other than one plain hex.
    spotlight = "#123456";
  };
}
