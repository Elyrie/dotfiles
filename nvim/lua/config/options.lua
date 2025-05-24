-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
return {
  {
    "mfussenegger/nvim-dap",
    config = function() end,
  },
  require("dap-python").setup(),
}
