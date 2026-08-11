-- Draft specs are full of placeholder links like `[LINK]()` where the target
-- hasn't been filled in yet. Typst's `#link("")` is a hard error ("URL must not
-- be empty") that kills the whole build, so unwrap any link with an empty (or
-- whitespace-only) target back to its plain label text.
function Link(link)
  if link.target:match("^%s*$") then
    return link.content
  end
end
