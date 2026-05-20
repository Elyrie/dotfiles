return {
  -- add nord
  {
    "shaunsingh/nord.nvim",
    config = function()
      -- Nord calls `hi clear` on every colorscheme activation, wiping any
      -- highlights set at plugin-load time. Use a ColorScheme autocmd so the
      -- overrides are re-applied *after* Nord resets everything.
      -- #7B88A8 is nord3_gui_bright — much more readable on the #2E3440 bg.
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "nord",
        callback = function()
          vim.api.nvim_set_hl(0, "NonText", { fg = "#7B88A8" })
          vim.api.nvim_set_hl(0, "SnacksPickerPathIgnored", { fg = "#7B88A8" })
        end,
      })
    end,
  },

  -- Configure LazyVim to load nord
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "nord",
    },
  },
}
