--- mermaid.lua — render ```mermaid fenced blocks to PNG and splice them in.
---
--- Renders via mermaid-cli (mmdc) driving a headless Chromium, so labels come
--- out as real rasterized text. (SVG is not usable here: mermaid puts labels in
--- <foreignObject>, which Typst's SVG renderer draws blank.)
---
--- Results are cached by content hash in $XDG_CACHE_HOME/pandoc-mermaid, so a
--- rebuild of an unchanged document costs nothing.
---
--- Overrides, all optional:
---   MERMAID_MMDC        path to mmdc               (default: first on PATH)
---   MERMAID_CHROMIUM    path to a chromium binary  (only consulted when mmdc
---                       does not already pin one; default: newest in /nix/store)
---   MERMAID_THEME       mermaid theme              (default: neutral — grayscale)
---   MERMAID_SCALE       raster oversampling        (default: 3)

local scale = tonumber(os.getenv("MERMAID_SCALE")) or 3
local theme = os.getenv("MERMAID_THEME") or "neutral"

local function home() return os.getenv("HOME") or "." end

local function exists(p)
  if not p or p == "" then return false end
  local f = io.open(p, "r")
  if f then f:close(); return true end
  return false
end

local function capture(cmd)
  local p = io.popen(cmd .. " 2>/dev/null")
  if not p then return nil end
  local out = p:read("*a") or ""
  p:close()
  return (out:gsub("%s+$", ""))
end

local function find_mmdc()
  local env = os.getenv("MERMAID_MMDC")
  if exists(env) then return env end
  local onpath = capture("command -v mmdc")
  if onpath and onpath ~= "" then return onpath end
  -- Fallback for a plain `npm i @mermaid-js/mermaid-cli` into the data dir.
  local bundled = home() .. "/.local/share/pandoc/mermaid/node_modules/.bin/mmdc"
  if exists(bundled) then return bundled end
  return nil
end

-- nixpkgs' mmdc is a shell wrapper that exports PUPPETEER_EXECUTABLE_PATH at a
-- chromium of its own; handing it a second one would just be noise.
local function mmdc_pins_own_chromium(path)
  local f = io.open(path, "r")
  if not f then return false end
  local head = f:read(4096) or ""
  f:close()
  return head:find("PUPPETEER_EXECUTABLE_PATH", 1, true) ~= nil
end

-- Otherwise we supply one. The nix-wrapped chromium bundles its own deps;
-- puppeteer's own download does not (it dies on a missing libnspr4.so here).
-- Glob rather than hardcode so the path survives version-hash changes.
local function find_chromium()
  local env = os.getenv("MERMAID_CHROMIUM")
  if exists(env) then return env end
  local found = capture("ls -d /nix/store/*-chromium-*/bin/chromium 2>/dev/null | sort | tail -1")
  if exists(found) then return found end
  local onpath = capture("command -v chromium || command -v google-chrome")
  if onpath and onpath ~= "" then return onpath end
  return nil
end

local function write_file(path, text)
  local f = assert(io.open(path, "wb"))
  f:write(text)
  f:close()
end

-- PNG intrinsic size in pixels, straight out of the IHDR chunk.
local function png_size(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local head = f:read(24) or ""
  f:close()
  if #head < 24 then return nil end
  local function be32(i)
    local a, b, c, d = head:byte(i, i + 3)
    return ((a * 256 + b) * 256 + c) * 256 + d
  end
  return be32(17), be32(21)
end

local cache_dir = (os.getenv("XDG_CACHE_HOME") or (home() .. "/.cache")) .. "/pandoc-mermaid"
os.execute("mkdir -p " .. cache_dir)

local function warn(msg) io.stderr:write("[mermaid.lua] " .. msg .. "\n") end

local warned = false
local function warn_once(msg)
  if not warned then
    warn(msg)
    warned = true
  end
end

-- Bump when the mmdc invocation changes, so stale cache entries are ignored.
local CACHE_VERSION = "2"

local function render(src)
  local key = pandoc.utils.sha1(
    table.concat({ src, theme, tostring(scale), CACHE_VERSION }, "|"))
  local png = cache_dir .. "/" .. key .. ".png"
  if exists(png) then return png end

  local mmdc = find_mmdc()
  if not mmdc then
    warn_once("mmdc not found — leaving mermaid blocks as code. " ..
              "It comes from `mermaid-cli` in home-manager; run `home-manager switch`.")
    return nil
  end
  local chromium = not mmdc_pins_own_chromium(mmdc) and find_chromium() or nil

  local mmd = cache_dir .. "/" .. key .. ".mmd"
  write_file(mmd, src)

  -- useMaxWidth:false gives the diagram's intrinsic size instead of mmdc's
  -- 800px fit — same geometry, but many more pixels to scale down from.
  local cfg = cache_dir .. "/" .. key .. ".config.json"
  write_file(cfg, '{"theme":"' .. theme .. '",' ..
    '"flowchart":{"useMaxWidth":false},' ..
    '"sequence":{"useMaxWidth":false},' ..
    '"gantt":{"useMaxWidth":false},' ..
    '"class":{"useMaxWidth":false},' ..
    '"state":{"useMaxWidth":false},' ..
    '"er":{"useMaxWidth":false},' ..
    '"pie":{"useMaxWidth":false}}')

  local pflag = ""
  if chromium then
    local pp = cache_dir .. "/puppeteer.json"
    write_file(pp, '{"executablePath":"' .. chromium .. '","args":["--no-sandbox"]}')
    pflag = " -p " .. pp
  end

  local cmd = string.format(
    '%s -i %s -o %s -c %s%s -b white -s %d -q',
    mmdc, mmd, png, cfg, pflag, scale)
  os.execute(cmd .. " >/dev/null 2>&1")

  if not exists(png) then
    warn_once("mmdc failed to render a diagram; run manually to see the error:\n  " .. cmd)
    return nil
  end
  return png
end

-- Live area of the reMarkable page: 157mm − 13mm − 12mm wide ≈ 374pt,
-- 209mm − 12mm − 11mm tall ≈ 527pt.
local TEXT_WIDTH_PT  = 374
local TEXT_HEIGHT_PT = 527

-- Mermaid's default label size is 16px ≈ 12pt at 1:1; everything below is about
-- how far that gets squeezed once the diagram is fitted to the page. Calibrated
-- against the device: ~6.5pt labels are comfortable at 226 PPI, ~5pt is not.
local BASE_FONT_PT = 12
local COMFORTABLE  = 6.0   -- above this, fit to the column and move on
local LEGIBLE      = 5.0   -- below this, no layout trick saves it — say so

-- A rotated diagram is one unbreakable block. Sized to the full text height it
-- never shares a page with the heading above it and orphans the previous one,
-- so give back a little height to keep it in the flow.
local ROTATED_MAX_HEIGHT = 0.85

function CodeBlock(block)
  if not block.classes:includes("mermaid") then return nil end

  local png = render(block.text)
  if not png then return nil end   -- leave the source visible rather than drop it

  local caption = block.attributes["caption"]
  -- mmdc rasterizes at `scale`× the CSS layout; 1px ≈ 0.75pt.
  local px_w, px_h = png_size(png)
  if not px_w or px_h == 0 then
    return pandoc.Para({ pandoc.Image({}, png, "",
      pandoc.Attr("", {}, { width = "100%" })) })
  end

  local nat_w = (px_w / scale) * 0.75
  local aspect = px_w / px_h

  -- Fitted flat, the diagram gets the column width. Turned a quarter turn it
  -- gets the page's long edge instead — worth ~1.4× on anything wide enough
  -- that its own height isn't the binding constraint.
  local flat_font = BASE_FONT_PT * math.min(1, TEXT_WIDTH_PT / nat_w)
  local rot_w = math.min(TEXT_HEIGHT_PT * ROTATED_MAX_HEIGHT, TEXT_WIDTH_PT * aspect)
  local rot_font = BASE_FONT_PT * math.min(1, rot_w / nat_w)

  if math.max(flat_font, rot_font) < LEGIBLE then
    warn(string.format(
      "a diagram is %.1f× wider than it is tall — its labels land at ~%.0fpt, " ..
      "too small to read on the tablet.\n" ..
      "              Try `flowchart TD` instead of `LR`, or split it in two.",
      aspect, math.max(flat_font, rot_font)))
  end

  if flat_font < COMFORTABLE and rot_font >= LEGIBLE and rot_font > flat_font + 0.5 then
    -- Rotate visually inside a block whose height is reserved for the turned
    -- diagram. `rotate` alone doesn't reflow, so the placement handles both
    -- centering and the space it needs.
    local typ = string.format(
      '#block(breakable: false, width: 100%%, height: %.1fpt, ' ..
      'place(center + horizon, rotate(90deg, image("%s", width: %.1fpt))))',
      rot_w, png, rot_w)
    if caption then
      typ = typ .. string.format(
        '\n#align(center, text(size: 8pt, fill: luma(115))[%s])', caption)
    end
    return pandoc.RawBlock("typst", typ)
  end

  local attr = pandoc.Attr("", {}, {
    width = nat_w >= TEXT_WIDTH_PT and "100%" or string.format("%.1fpt", nat_w),
  })
  local img = pandoc.Image(caption and pandoc.Str(caption) or {}, png, "", attr)
  if caption then
    return pandoc.Figure(pandoc.Plain(img), { pandoc.Str(caption) })
  end
  return pandoc.Para({ img })
end
