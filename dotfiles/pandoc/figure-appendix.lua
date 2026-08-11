--- figure-appendix.lua — give every image a full page at the back of the PDF.
---
--- On a 157mm-wide reMarkable page an inline diagram is roughly a third of the
--- size it had on the web, and a diagram is exactly the thing you most need to
--- see. This filter leaves a legible thumbnail in the flow, makes it a tappable
--- link, and reprints each image on its own page in an appendix — turned
--- sideways when the image is wide enough that rotating buys real size.
---
--- Emits calls to `rm-thumb` / `rm-plate`, which live in remarkable.typst.
---
--- Two preparation steps happen first, because both change how big the image
--- can be drawn and neither is recoverable later:
---
---   * **Trim.** Images lifted off the web routinely carry a wide blank canvas
---     — one of the diagrams in the article this was built for is 1050px wide
---     with only 492px of content. Scaled to the page width, that padding is
---     what fills the page. `-trim` recovers roughly 2× on such an image.
---   * **Grayscale.** The Pure has no color; letting ImageMagick do the
---     luminance conversion beats leaving it to the device, and it shrinks the
---     PDF. Off via `figure-grayscale: false` if a figure depends on hue.
---
--- Results are cached by content hash under $XDG_CACHE_HOME/pandoc-figures, so
--- a rebuild of an unchanged document costs nothing. Without ImageMagick on
--- PATH the filter still works — it just uses the images as they are.
---
--- It also strips the reader-chrome sentences web-to-markdown exporters leave
--- behind ("Press enter or click to view image in full size").
---
--- Metadata knobs (set in the defaults file or the document's YAML header):
---   figure-appendix: false        leave images inline, no appendix
---   figure-thumb-width: 62%       inline thumbnail width, as a Typst length
---   figure-trim: false            keep the original canvas padding
---   figure-grayscale: false       keep color
---   figure-invert-dark: false     leave dark-theme screenshots dark
---   figure-adopt-captions: false  don't pull the following line into a caption
---   figure-appendix-title: "…"    appendix heading text

local options = {
  appendix = true,
  thumb_width = "62%",
  trim = true,
  grayscale = true,
  invert_dark = true,
  adopt_captions = true,
  appendix_title = "Appendix — figures at full size",
}

--- Invert an image when fewer than this fraction of its pixels are lighter than
--- 20% luma. The measured split on real articles is not close — dark-theme code
--- screenshots land near 0.07, every light diagram above 0.97 — so a threshold
--- anywhere in the middle is safe.
local DARK_FRACTION = 0.5

--- Whole-paragraph matches (lowercased, trimmed), so real prose is never at
--- risk of being swept up.
local chrome = {
  "^press enter or click to view image in full size$",
  "^click to view image in full size$",
  "^zoom image will be displayed$",
  "^open in app$",
}

--- A short trailing line is treated as the figure's caption when it looks like
--- a caption rather than a sentence of body text: brief, and unterminated.
local CAPTION_MAX_CHARS = 90

local plates = {}          -- ordered { n = , path = , ratio = , caption = }

local function home() return os.getenv("HOME") or "." end

local function exists(path)
  if not path or path == "" then return false end
  local handle = io.open(path, "rb")
  if handle then handle:close(); return true end
  return false
end

local function capture(cmd)
  local pipe = io.popen(cmd .. " 2>/dev/null")
  if not pipe then return nil end
  local out = pipe:read("*a") or ""
  pipe:close()
  return (out:gsub("%s+$", ""))
end

local function dirname(path)
  return path and path:match("^(.*)/[^/]*$") or "."
end

local function trimmed(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- Image srcs in exported markdown are percent-encoded ("%7BpageTitle%7D/x.png").
local function url_decode(s)
  return (s:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end))
end

--- Typst string literal — these paths really do contain `{`, `}` and spaces.
local function typst_string(s)
  return '"' .. s:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
end

--- Single-quoted shell word, safe for the `{pageTitle}` directories and spaces
--- that web exports produce.
local function shell_quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

local warned = false
local function warn_once(msg)
  if not warned then
    io.stderr:write("[figure-appendix.lua] " .. msg .. "\n")
    warned = true
  end
end

local cache_dir = (os.getenv("XDG_CACHE_HOME") or (home() .. "/.cache")) .. "/pandoc-figures"
os.execute("mkdir -p " .. shell_quote(cache_dir))

--- Bump when the magick invocation changes, so stale entries are ignored.
local CACHE_VERSION = "2"

local magick = nil
local function find_magick()
  if magick == nil then
    local found = capture("command -v magick || command -v convert")
    magick = (found and found ~= "") and found or false
  end
  return magick or nil
end

--- Flattening onto white has to come first and has to match what the render
--- does. A diagram saved with a transparent background measures as 16% light
--- un-flattened and 99% flattened — measuring the raw file inverts exactly the
--- clean line diagrams that needed no help.
local FLATTEN = "-background white -alpha remove -alpha off"

--- Fraction of pixels lighter than 20% luma, after the same flatten and trim
--- the render will use. nil if it can't be measured.
local function light_fraction(tool, path)
  local trim = options.trim and "-fuzz 1% -trim +repage" or ""
  local out = capture(table.concat({
    shell_quote(tool), shell_quote(path), FLATTEN, trim,
    "-colorspace Gray -threshold 20% -format '%[fx:mean]' info:",
  }, " "))
  return tonumber(out)
end

--- Trim the dead canvas, drop to gray, and flip a dark-theme screenshot. The
--- prepared path, or the original when there's nothing to do (or nothing to do
--- it with).
local function prepare(path, data)
  if not (options.trim or options.grayscale or options.invert_dark) then return path end
  local tool = find_magick()
  if not tool then
    warn_once("ImageMagick not found — using images as-is (blank canvas padding " ..
              "will shrink the figure plates).")
    return path
  end

  local invert = options.invert_dark and (light_fraction(tool, path) or 1) < DARK_FRACTION
  local key = pandoc.utils.sha1(table.concat({
    pandoc.utils.sha1(data), tostring(options.trim), tostring(options.grayscale),
    tostring(invert), CACHE_VERSION,
  }, "|"))
  local out = cache_dir .. "/" .. key .. ".png"
  if exists(out) then return out end

  local steps = { shell_quote(tool), shell_quote(path), FLATTEN }
  -- 1% fuzz so JPEG ringing along a white edge still counts as blank.
  if options.trim then steps[#steps + 1] = "-fuzz 1% -trim +repage" end
  if options.grayscale then steps[#steps + 1] = "-colorspace Gray" end
  if invert then steps[#steps + 1] = "-negate" end
  steps[#steps + 1] = shell_quote(out)
  os.execute(table.concat(steps, " "))
  return exists(out) and out or path
end

--- Absolute path + aspect ratio for an image we can handle, or nil for remote
--- URLs and missing files. Typst runs with `--root=/`, so absolute paths work.
local function resolve(src)
  if src:match("^%a[%w+.-]*://") then return nil end
  local path = url_decode(src)
  if not path:match("^/") then
    path = dirname(PANDOC_STATE.input_files[1] or "./x") .. "/" .. path
  end
  local handle = io.open(path, "rb")
  if not handle then return nil end
  local data = handle:read("a")
  handle:close()

  path = prepare(path, data)
  local prepared = io.open(path, "rb")
  if prepared then data = prepared:read("a"); prepared:close() end

  local ok, size = pcall(pandoc.image.size, data)
  if not ok or not size or not size.width or not size.height or size.height == 0 then
    return nil
  end
  return path, size.width / size.height
end

--- Register an image and return the Typst thumbnail that stands in for it.
--- nil when the image can't be handled, so the caller leaves it untouched.
local function to_thumb(src)
  local path, ratio = resolve(src)
  if not path then return nil end
  local n = #plates + 1
  plates[n] = { n = n, path = path, ratio = ratio }
  return n, pandoc.RawBlock("typst", string.format(
    "#rm-thumb(%d, %s, %.4f, width: %s)", n, typst_string(path), ratio, options.thumb_width))
end

local function is_chrome(block)
  local text = trimmed(pandoc.utils.stringify(block)):lower()
  for _, pattern in ipairs(chrome) do
    if text:match(pattern) then return true end
  end
  return false
end

--- A block is "just an image" when stripping the image leaves only whitespace —
--- which covers `![](x.png)` both as a bare Para and inside a Figure.
local function lone_image(block)
  if not block or not block.content then return nil end
  local found
  for _, inline in ipairs(block.content) do
    if inline.t == "Image" then
      if found then return nil end
      found = inline
    elseif inline.t ~= "Space" and inline.t ~= "SoftBreak" then
      return nil
    end
  end
  return found
end

--- The line under an image is a caption if it is short and doesn't close like a
--- sentence. Deliberately strict: mistaking body text for a caption would hide
--- it from the page, whereas a missed caption just stays where it already was.
local function looks_like_caption(block)
  if not options.adopt_captions then return false end
  if not block or block.t ~= "Para" then return false end
  local text = trimmed(pandoc.utils.stringify(block))
  return #text > 0 and #text <= CAPTION_MAX_CHARS and not text:match("[.!?:]$")
end

local function image_of(block)
  if block.t == "Para" or block.t == "Plain" then return lone_image(block) end
  if block.t == "Figure" and #block.content == 1 then return lone_image(block.content[1]) end
  return nil
end

function Meta(meta)
  local function flag(name, field)
    if meta[name] ~= nil then options[field] = meta[name] ~= false end
  end
  flag("figure-appendix", "appendix")
  flag("figure-trim", "trim")
  flag("figure-grayscale", "grayscale")
  flag("figure-invert-dark", "invert_dark")
  flag("figure-adopt-captions", "adopt_captions")
  if meta["figure-thumb-width"] then
    options.thumb_width = pandoc.utils.stringify(meta["figure-thumb-width"])
  end
  if meta["figure-appendix-title"] then
    options.appendix_title = pandoc.utils.stringify(meta["figure-appendix-title"])
  end
  return meta
end

--- The headings a figure sits under, used as a fallback label in the appendix
--- index when the source gave the figure no caption of its own. Both levels are
--- tracked because neither is enough alone: in a bundle of stitched documents
--- the nearest heading is usually a boilerplate section name ("Solution")
--- repeated in every document, while the H1 alone can't tell two figures in the
--- same document apart.
local current_document = nil
local current_section = nil

--- Long enough to tell two figures apart, short enough to stay on one row of
--- the appendix index — a wrapped row breaks the dotted leader alignment and
--- reads as a layout bug. Applies to real captions too, which are allowed to be
--- longer than this in the plate footer, where there is a whole page of width.
local INDEX_LABEL_MAX_CHARS = 54

local function shorten(label)
  if not label or #label <= INDEX_LABEL_MAX_CHARS then return label end
  -- Cut at the last word boundary that fits, so it reads as elision rather
  -- than truncation mid-word.
  local cut = label:sub(1, INDEX_LABEL_MAX_CHARS)
  return (cut:match("^(.*)%s%S*$") or cut) .. "…"
end

local function describe_location()
  if current_document and current_section then
    return current_document .. " — " .. current_section
  end
  return current_document or current_section
end

function Blocks(blocks)
  local out = pandoc.Blocks({})
  local skip_next_caption_for = nil
  for _, block in ipairs(blocks) do
    local image = options.appendix and image_of(block)
    if block.t == "Header" then
      if block.level == 1 then
        current_document = trimmed(pandoc.utils.stringify(block))
        current_section = nil
      else
        current_section = trimmed(pandoc.utils.stringify(block))
      end
    end
    if is_chrome(block) then
      -- exporter chrome, drop it
    elseif skip_next_caption_for and looks_like_caption(block) then
      plates[skip_next_caption_for].caption = trimmed(pandoc.utils.stringify(block))
      skip_next_caption_for = nil
    elseif image then
      local n, thumb = to_thumb(image.src)
      if thumb then plates[n].section = describe_location() end
      out:insert(thumb or block)
      skip_next_caption_for = thumb and n or nil
    else
      out:insert(block)
      skip_next_caption_for = nil
    end
  end
  return out
end

function Pandoc(doc)
  if #plates == 0 then return doc end
  local blocks = doc.blocks
  blocks:insert(pandoc.RawBlock("typst", "#pagebreak(weak: true)"))
  blocks:insert(pandoc.Header(1, options.appendix_title))
  blocks:insert(pandoc.Para({ pandoc.Str(string.format(
    "%d figure%s, one per page. The link under each returns you to the point in the text it came from.",
    #plates, #plates == 1 and "" or "s")) }))

  local rows = {}
  for _, plate in ipairs(plates) do
    rows[#rows + 1] = string.format("(n: %d, caption: %s, section: %s)", plate.n,
      plate.caption and typst_string(shorten(plate.caption)) or "none",
      plate.section and typst_string(shorten(plate.section)) or "none")
  end
  blocks:insert(pandoc.RawBlock("typst",
    "#rm-plate-index((" .. table.concat(rows, ", ") .. ",))"))

  for _, plate in ipairs(plates) do
    blocks:insert(pandoc.RawBlock("typst", string.format(
      "#rm-plate(%d, %s, %.4f, caption: %s)", plate.n, typst_string(plate.path),
      plate.ratio, plate.caption and typst_string(plate.caption) or "none")))
  end
  return doc
end

--- Meta has to be read before any Blocks are walked.
return {
  { Meta = Meta },
  { Blocks = Blocks },
  { Pandoc = Pandoc },
}
