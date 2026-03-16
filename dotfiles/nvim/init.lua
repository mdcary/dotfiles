-- ~/.config/nvim/init.lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local hotpotpath = vim.fn.stdpath("data") .. "/lazy/hotpot.nvim"

-- 1. Bootstrap Hotpot (The Lisp Compiler)
if not vim.uv.fs_stat(hotpotpath) then
  vim.fn.system({"git", "clone", "--filter=blob:none", "https://github.com/rktjmp/hotpot.nvim.git", hotpotpath})
end
vim.opt.rtp:prepend(hotpotpath)
require("hotpot").setup()

-- 2. Bootstrap Lazy.nvim
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({"git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath})
end
vim.opt.rtp:prepend(lazypath)

-- 3. Hand over control to your Fennel config (fnl/config.fnl)
require("config")
