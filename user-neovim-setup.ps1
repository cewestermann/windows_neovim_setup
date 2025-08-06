$ErrorActionPreference = "Stop"

function Assert-Exists($cmd) {
	if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
		throw "Required command '$cmd' was not found in PATH."
	} 
} 

Assert-Exists "nvim"
Assert-Exists "git"
Assert-Exists "clang"

$Local 		= $env:LOCALAPPDATA
$nvim_config 	= Join-Path $Local "nvim"
$nvim_data 	= Join-Path $Local "nvim-data"
$site_dir 	= Join-Path $nvim_data "site"
$packer_dir 	= Join-Path $site_dir "pack\packer\start\packer.nvim"
$init_lua 	= Join-Path $nvim_config "init.lua"
$plugins_dir 	= Join-Path $nvim_config "after\plugins"
$treesitter 	= Join-Path $plugins_dir "treesitter.lua"
$user_dir 	= Join-Path $nvim_config "lua\chris"
$user_init 	= Join-Path $user_dir "init.lua"
$user_packer    = Join-Path $user_dir "packer.lua"
$remap 		= Join-Path $user_dir "remap.lua"
$set 		= Join-Path $user_dir "set.lua"

New-Item -ItemType Directory -Force -Path $nvim_config, $site_dir, (Split-Path $packer_dir), $plugins_dir, $user_dir | Out-Null

if (-not (Test-Path $packer_dir)) {
  git clone --depth 1 https://github.com/wbthomason/packer.nvim $packer_dir | Out-Null
}

# Write init.lua (always ensure it requires your module)
@'
require("chris")
'@ | Set-Content -Encoding UTF8 -Path $init_lua

# Set up remap.lua
@'
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
'@ | Set-Content -Encoding UTF8 -Path $remap

# Set up user init.lua
@'
require("chris.set")
require("chris.remap")
require("chris.packer")
'@ | Set-Content -Encoding UTF8 -Path $user_init

# Set up set.lua
@'
vim.opt.guicursor = ""

vim.opt.nu = true
vim.opt.relativenumber = false

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"

vim.g.mapleader = " "
'@ | Set-Content -Encoding UTF8 -Path $set

# Set up packer.lua
@'
local fn = vim.fn

local ensure_packer = function()
	local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
	if fn.empty(fn.glob(install_path)) > 0 then
		fn.system({ "git", "clone", "--depth", "1",
			"https://github.com/wbthomason/packer.nvim", install_path })
		vim.cmd("packadd packer.nvim")
		return true
	end
	return false
end
local packer_bootstrap = ensure_packer()

require("packer").startup(function(use)
	use "wbthomason/packer.nvim"
	use { "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" }
	if packer_bootstrap then require("packer").sync() end
end) 

'@ | Set-Content -Encoding UTF8 -Path $user_packer

# Set up treesitter.lua
@'
require("nvim-treesitter.install").compilers = { "clang", "gcc", "cl" }

require'nvim-treesitter.configs'.setup {
  -- A list of parser names, or "all" (the listed parsers MUST always be installed)
  ensure_installed = { "c", "cpp", "python", "rust", "query", "markdown", "markdown_inline" },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
  auto_install = true,

  highlight = {
    enable = true,
    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },

  parser_install_dir = vim.fn.stdpath("data") .. "/site",
}
'@ | Set-Content -Encoding UTF8 -Path $treesitter


# Final powershell moves
nvim --headless "+qall" 2>$null

nvim --headless "+PackerSync" "+TSUpdateSync" "+qall"

Write-Host "`nAll set. Parsers are in: $site_dir\parser"
